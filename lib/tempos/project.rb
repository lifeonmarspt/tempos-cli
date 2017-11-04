require 'shellwords'
require 'fileutils'

require_relative './plumbing'
require_relative './version_controlled_plumbing'

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

    def commit_a message
      exec "commit", "-am", message
    end
  end

  class NoGit < Struct.new(:root)
    def pull; end
    def commit message, filename; end
    def commit_a message; end
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
      self.root = opts.fetch(:root) { ENV["TEMPOS_ROOT"] }
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
    attr_accessor :plumbing, :identifier, :username

    def initialize identifier, username, opts = {}
      self.plumbing = VersionControlledPlumbing.new(Plumbing.new(opts), NoGit.new)
      self.identifier = identifier
      self.username = username
    end

    def status
      self.plumbing.user_entries(identifier, username).
        select { |line| ["start", "stop"].include? line[2] }.
        map { |line| line[2] }.
        last
    end

    def budget
      self.plumbing.metadata_entries(identifier).
        select { |line| ["set-budget", "add-budget"].include? line[2] }.
        reduce([0, nil]) { |(budget, currency), line|
          if line[2] == "set-budget"
            [Integer(line[3]), line[4]]
          elsif line[2] == "add-budget" && currency == line[4]
            [budget + Integer(line[3]), currency]
          else
            raise
          end
        }
    end

    def deadline
      self.plumbing.metadata_entries(identifier).
        select { |line| ["set-deadline"].include? line[2] }.
        map { |line| Integer(line[3]) }.
        last
    end

    def start timestamp, timezone
      raise AlreadyStarted if status == "start"

      self.plumbing.add_user_entry identifier, username, timestamp, timezone, "start"
    end

    def stop timestamp, timezone
      raise NotStarted if status == "stop"

      self.plumbing.add_user_entry identifier, username, timestamp, timezone, "stop"
    end

    def add timestamp, timezone, duration
      self.plumbing.add_user_entry identifier, username, timestamp, timezone, "add #{duration}"
    end

    def remove timestamp, timezone, duration
      self.plumbing.add_user_entry identifier, username, timestamp, timezone, "remove #{duration}"
    end

    def set_budget timestamp, timezone, amount, currency
      self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-budget #{amount} #{currency}"
    end

    def add_budget timestamp, timezone, amount, currency
      self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-budget #{amount} #{currency}"
    end

    def set_deadline timestamp, timezone, deadline
      self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-deadline #{deadline}"
    end

    def set_rate timestamp, timezone, amount, currency, member
      if entry
        self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-rate #{amount} #{currency}"
      else
        self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-rate #{amount} #{currency} #{member}"
      end
    end
  end
end
