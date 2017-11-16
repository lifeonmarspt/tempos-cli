require 'chronic_duration'
require 'tzinfo'

require_relative '../tempos/config'
require_relative '../tempos/project'
require_relative '../tempos/currency'
require_relative '../tempos/plumbing'
require_relative '../tempos/reducer'
require_relative '../tempos/reports/daily'

require_relative '../tempos/support/object_as'
require_relative '../tempos/support/git'

module Tempos
  module Commands
    class Command
      attr_accessor :options, :config, :plumbing, :git

      def initialize options = {}
        self.options = options
        self.config = Tempos::Config.new(options)
        self.plumbing = Tempos::Plumbing.new(root)
        self.git = Tempos::Support::Git.new(root)
      end

      def root
        config.root
      end

      def project_identifier
        config.project_identifier
      end

      def username
        config.username
      end

      def timezone
        config.timezone
      end

      def project
        Tempos::Project.new project_identifier, username, plumbing
      end

      def timestamp
        Time.now.utc.to_i
      end

      def run *args
        ChronicDuration.raise_exceptions = true

        git.pull

        run2 *args

        if git.dirty?
          git.add "."
          git.commit "bin/tempos #{ARGV.join(" ")}"
          git.push
        end
      rescue Tempos::ProjectDefinitionFileNotFound
        $stderr.puts "unable to detect current project: no .tempos file found"
        exit 1
      rescue Tempos::AlreadyStarted
        $stderr.puts "unable to start tracking time in #{project_identifier}: already started"
        exit 1
      rescue Tempos::NotStarted
        $stderr.puts "unable to stop tracking time in #{project_identifier}: not started"
        exit 1
      rescue ChronicDuration::DurationParseError
        $stderr.puts "unable to parse duration"
        exit 1
      rescue Tempos::Currency::Invalid
        $stderr.puts "unable to set budget: invalid currency"
        exit 1
      end
    end

    class Start < Command
      def run2
        project.start(timestamp, timezone)
      end
    end

    class Stop < Command
      def run2
        project.stop(timestamp, timezone)
      end
    end

    class Add < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.add(timestamp, timezone, duration)
      end
    end

    class Remove < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.remove(timestamp, timezone, duration)
      end
    end

    class ShowConfiguration < Command
      def run2
        puts "root: #{config.root}"
        puts "username: #{config.username}"
        puts "timezone: #{config.timezone}"
      end
    end

    class ShowCurrentProject < Command
      def run2
        puts config.project_identifier
      end
    end

    class Projects < Command
      def run2
        puts plumbing.projects
      end
    end

    class SetCurrentProject < Command
      def run2 identifier
        config.set_current_project identifier
      end
    end

    class Status < Command
      def run2
        plumbing.
          projects.
          map { |identifier| Tempos::Reducer.new(plumbing).reduce(identifier) }.
          flat_map { |state| state.started.keys.map { |member| [state.identifier, member] } }.
          select { |(identifier, member)| options[:'all-users'] || username == member }.
          select { |(identifier, member)| options[:'all-projects'] || project_identifier == identifier }.
          map { |identifier, member| "#{identifier} #{member} started" }.
          each { |line| puts line }
      end
    end

    class SetBudget < Command
      def run2(amount, currency)
        amount = Integer(amount)
        currency = Tempos::Currency.normalize currency

        raise if currency != project.budget[1]

        project.set_budget(timestamp, timezone, amount, currency)
      end
    end

    class SetDeadline < Command
      def run2(deadline)
        deadline = TZInfo::Timezone.new(timezone).local_to_utc(Date.parse(deadline).to_time).to_i

        project.set_deadline(timestamp, timezone, deadline)
      end
    end

    class SetRate < Command
      def run2(amount, currency, member)
        amount = Integer(amount)
        currency = Tempos::Currency.normalize currency

        project.set_rate(timestamp, timezone, amount, currency, member)
      end
    end

    class Budget < Command
      def run2
        puts Tempos::Reducer.new(plumbing).reduce(project_identifier).budget.join(" ")
      end
    end

    class Deadline < Command
      def run2
        puts Time.at(Tempos::Reducer.new(plumbing).reduce(project_identifier).deadline).strftime("%Y-%m-%d")
      end
    end

    class Invoice < Command
      def run2
        project.invoice(timestamp, timezone)
      end
    end

    class Report < Command
      def run2
        state = Tempos::Reducer.new(plumbing).reduce(project_identifier)

        puts "name:     #{state.identifier}"
        puts "budget:   #{state.budget.join(" ")}"
        puts "deadline: #{state.deadline&.as { |d| Time.at(d) }&.strftime("%Y-%m-%d") || "N/A"}"

        puts "cost:"
        state.times.each do |member, amounts|
          puts "  #{"#{member}:".ljust(32)} #{amounts.map { |k,v| "#{(k[0] * v / 3600.0).round(2)}".rjust(6) +" #{k[1]}" }.join(" ")}"
        end
      end
    end

    class DailyReport < Command
      def run2
        Tempos::Reports::Daily.new(plumbing).reduce(project_identifier).each do |day, members|
          puts "#{day}:"

          members.each do |member, amount|
            puts "  #{"#{member}:".ljust(32)} #{"#{(amount / 3600.0).round(2)}".rjust(6)}"
          end
        end
      end
    end
  end
end
