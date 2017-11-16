require 'shellwords'

module Tempos
  module Support
    class Git < Struct.new(:root)
      def exec *command
        `#{["git", "-C", root, *command].map { |arg| Shellwords.escape(arg) }.join(" ")}`
      end

      def pull
        exec "pull", "--quiet"
      end

      def push
        exec "push"
      end

      def commit message
        exec "commit", "-m", message
      end

      def add pathspec
        exec "add", pathspec
      end

      def dirty?
        !exec("status", "--porcelain").empty?
      end
    end

    class NoGit < Struct.new(:root)
      def pull; end
      def push; end
      def commit message; end
      def add pathspec; end
      def dirty?; false end
    end
  end
end
