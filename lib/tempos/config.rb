require 'shellwords'

module Tempos
  class ProjectDefinitionFileNotFound < StandardError
  end

  class RootDirectoryNotFound < StandardError
  end

  class DirectoryTraversal
    def traverse directory
      Enumerator.new do |y|
        loop do
          y << directory

          break if directory == "/"

          directory = File.dirname(directory)
        end
      end
    end
  end

  class Config
    FILENAME = ".tempos"
    attr_accessor :options, :project_file

    def initialize options
      self.options = options

      self.project_file = find_project_file
    end

    def cwd
      options.fetch(:cwd) { Dir.getwd }
    end

    def root
      options.fetch(:root) { ENV.fetch("TEMPOS_ROOT", "") }.tap do |dir|
        Dir.exists?(dir) or raise RootDirectoryNotFound
      end
    end

    def project_identifier
      options.fetch(:project) { default_project_identifier }
    end

    def username
      options.fetch(:member) { default_username }
    end

    def timezone
      options.fetch(:timezone) { default_timezone }
    end

    def timestamp
      ts = options.fetch(:timestamp) { default_timestamp }

      case ts
      when Integer
        ts
      when /\A\d+\z/
        Integer(ts)
      when /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}\z/
        DateTime.parse(ts).to_time.utc.to_i
      else
        raise
      end
    end

    def find_project_file
      DirectoryTraversal.new.
        traverse(cwd).lazy.
        map { |directory| File.join directory, FILENAME }.
        select { |directory| File.exists? directory }.
        first
    end

    def client
      project_file or raise ProjectDefinitionFileNotFound

      File.read(project_file).strip.split("/").first
    end

    def project
      project_file or raise ProjectDefinitionFileNotFound

      File.read(project_file).strip.split("/").last
    end

    def set_current_project  identifier
      File.open(project_file || File.join(cwd, FILENAME), "w+") do |file|
        file.puts identifier
      end
    end

    def default_project_identifier
      "#{client}/#{project}"
    end

    def default_username
      `git -C #{Shellwords.escape(cwd)} config user.email`.strip
    end

    def default_timezone
      File.readlink("/etc/localtime").split("/").last(2).join("/")
    end

    def default_timestamp
      Time.now.utc.to_i
    end
  end
end
