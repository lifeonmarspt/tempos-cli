require 'shellwords'
require 'fileutils'

require_relative './reducer'

module Tempos
  class AlreadyStarted < StandardError
  end

  class NotStarted < StandardError
  end

  class Project
    attr_accessor :identifier, :username, :plumbing

    def initialize identifier, username, plumbing
      self.identifier = identifier
      self.username = username
      self.plumbing = plumbing
    end

    def started?
      Tempos::Reducer.new(plumbing).reduce(identifier).started.key?(username)
    end

    def start timestamp, timezone
      raise AlreadyStarted if started?

      self.plumbing.add_user_entry identifier, username, timestamp, timezone, "start"
    end

    def stop timestamp, timezone
      raise NotStarted if !started?

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
      if member
        self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-rate #{amount} #{currency}"
      else
        self.plumbing.add_metadata_entry identifier, timestamp, timezone, "set-rate #{amount} #{currency} #{member}"
      end
    end

    def invoice timestamp, timezone
      self.plumbing.add_metadata_entry identifier, timestamp, timezone, "invoice"
    end
  end
end
