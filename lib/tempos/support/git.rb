module Tempos
  module Support
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
end
