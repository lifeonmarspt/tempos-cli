require 'shellwords'

module Tempos
  class ProjectDefinitionFileNotFound < StandardError
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
    attr_accessor :cwd, :project_file

    def initialize cwd = nil
      self.cwd = cwd || Dir.getwd

      self.project_file = find_project_file
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

    def project_identifier
      "#{client}/#{project}"
    end

    def username
      `git -C #{Shellwords.escape(cwd)} config user.email`.strip
    end

    def timezone
      File.readlink("/etc/localtime").split("/").last(2).join("/")
    end
  end
end
