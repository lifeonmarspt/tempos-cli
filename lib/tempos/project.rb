require 'shellwords'
require 'fileutils'

module Tempos
  class Git < Struct.new(:root)
    def exec *command
      system "git", "--quiet", "-C", root, *command
    end

    def pull
      exec "pull"
    end

    def push
      exec "push"
    end

    def commit message, filename
      exec "commit", "-m", message, filename
    end
  end

  class NoGit
    def pull; end
    def commit message, filename; end
    def push; end
  end
end

module Tempos
  class AlreadyStarted < StandardError
  end

  class NotStarted < StandardError
  end

  class Repository
    attr_accessor :root

    def initialize opts = {}
      self.root = opts[:root] || ENV["TEMPOS_ROOT"]
    end

    def projects
      Dir[File.join(root, "*", "*")].map do |path|
        path.split("/").last(2).join("/")
      end
    end

    def members project_identifier
      Dir[File.join(root, project_identifier, "*@*")].map do |path|
        path.split("/").last
      end
    end
  end

  class Project
    attr_accessor :identifier, :username
    attr_accessor :root, :git

    def initialize identifier, username, opts = {}
      self.identifier = identifier
      self.username = username

      self.root = opts[:root] || ENV["TEMPOS_ROOT"]

      self.git = opts.fetch(:git, false) ? Git.new(root) : NoGit.new
    end

    def filepath
      File.join(root, identifier, username)
    end

    def status
      git.pull

      (File.readlines(filepath) rescue []).
        reject { |line| line.start_with? "#" }.
        reject { |line| line.strip.empty? }.
        map { |line| line.split(/\s+/) }.

        select { |line| ["start", "stop"].include? line[2] }.
        #map { |line| line[3] ? [line[3], *line[1...-1]] : line }.
        sort_by { |line| line[0].to_i }.
        map { |line| line[2] }.
        last
    end

    def add_entry timestamp, timezone, command
      git.pull

      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, "a") do |file|
        file.puts "#{timestamp} #{timezone} #{command}"
      end

      git.commit command, filepath
      git.push
    end

    def start timestamp, timezone
      if status == "start"
        raise AlreadyStarted
      end

      add_entry timestamp, timezone, "start"
    end

    def stop timestamp, timezone
      if status == "stop"
        raise NotStarted
      end

      add_entry timestamp, timezone, "stop"
    end

    def add timestamp, timezone, duration
      add_entry timestamp, timezone, "add #{duration}"
    end

    def remove timestamp, timezone, duration
      add_entry timestamp, timezone, "remove #{duration}"
    end
  end
end
