require 'chronic_duration'

require_relative '../tempos/config'
require_relative '../tempos/project'

module Tempos
  module Commands
    class Command
      attr_accessor :config

      def initialize
        self.config = Tempos::Config.new
      end

      def project
        Tempos::Project.new(config.client, config.project, config.username)
      end

      def run *args
        ChronicDuration.raise_exceptions = true

        run2 *args
      rescue Tempos::ProjectDefinitionFileNotFound
        $stderr.puts "unable to detect current project: no .tempos file found"
        exit 1
      rescue Tempos::AlreadyStarted
        $stderr.puts "unable to start tracking time in #{config.project_identifier}: already started"
        exit 1
      rescue Tempos::NotStarted
        $stderr.puts "unable to stop tracking time in #{config.project_identifier}: not started"
        exit 1
      rescue ChronicDuration::DurationParseError
        $stderr.puts "unable to parse duration"
        exit 1
      end
    end

    class Start < Command
      def run2
        project.start(Time.now.utc.to_i, config.timezone)
      end
    end

    class Stop < Command
      def run2
        project.stop(Time.now.utc.to_i, config.timezone)
      end
    end

    class Add < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.add(Time.now.utc.to_i, config.timezone, duration)
      end
    end

    class Remove < Command
      def run2 duration
        duration = ChronicDuration.parse(duration)

        project.remove(Time.now.utc.to_i, rc.timezone, duration)
      end
    end

    class ShowCurrentProject < Command
      def run2
        puts config.project_identifier
      end
    end

    class Status < Command
      def run2
        puts "#{config.project_identifier} #{project.status}"
      end
    end
  end
end
