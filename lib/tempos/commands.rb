require 'chronic_duration'
require 'tzinfo'

require_relative '../tempos/config'
require_relative '../tempos/project'
require_relative '../tempos/currency'

module Tempos
  module Commands
    class Command
      attr_accessor :config, :options

      def initialize options = {}
        self.options = options
        self.config = Tempos::Config.new
      end

      def project_identifier
        options.fetch(:project) { config.project_identifier }
      end

      def username
        options.fetch(:member) { config.username }
      end

      def timezone
        options.fetch(:timezone) { config.timezone }
      end

      def project
        Tempos::Project.new project_identifier, username
      end

      def repository
        Tempos::Repository.new
      end

      def run *args
        ChronicDuration.raise_exceptions = true

        run2 *args
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
        project.start(Time.now.utc.to_i, timezone)
      end
    end

    class Stop < Command
      def run2
        project.stop(Time.now.utc.to_i, timezone)
      end
    end

    class Add < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.add(Time.now.utc.to_i, timezone, duration)
      end
    end

    class Remove < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.remove(Time.now.utc.to_i, timezone, duration)
      end
    end

    class ShowCurrentProject < Command
      def run2
        puts config.project_identifier
      end
    end

    class SetCurrentProject < Command
      def run2 identifier
        config.set_current_project identifier
      end
    end

    class Status < Command
      def run2
        repository.
          projects.
          flat_map { |identifier| repository.members(identifier).map { |member| [identifier, member] } }.
          map { |(identifier, member)| Tempos::Project.new(identifier, member) }.
          select { |project| options[:'all-users'] || username == project.username }.
          select { |project| options[:'all-projects'] || project_identifier == project.identifier }.
          select { |project| project.status == "start" }.
          map { |project| "#{project.identifier} #{project.username} started" }.
          each { |line| puts line }
      end
    end

    class SetBudget < Command
      def run2(amount, currency)
        amount = Integer(amount)
        currency = Tempos::Currency.normalize currency

        raise if currency != project.budget[1]

        project.set_budget(Time.now.utc.to_i, timezone, amount, currency)
      end
    end

    class SetDeadline < Command
      def run2(deadline)
        deadline = TZInfo::Timezone.new(timezone).local_to_utc(Date.parse(deadline).to_time).to_i

        project.set_deadline(Time.now.utc.to_i, timezone, deadline)
      end
    end

    class SetRate < Command
      def run2(amount, currency, member)
        amount = Integer(amount)
        currency = Tempos::Currency.normalize currency

        project.set_rate(Time.now.utc.to_i, timezone, amount, currency, member)
      end
    end

    class Budget < Command
      def run2
        puts project.budget.join(" ")
      end
    end

    class Deadline < Command
      def run2
        puts Time.at(project.deadline).strftime("%Y-%m-%d")
      end
    end

    class Report < Command
      def run2
        puts project
      end
    end
  end
end
