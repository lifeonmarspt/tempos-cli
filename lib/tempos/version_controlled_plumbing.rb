module Tempos
  class VersionControlledPlumbing
    attr_accessor :plumbing, :git

    def initialize plumbing, git
      self.plumbing = plumbing
      self.git = git
    end

    class <<self
      def readonly method_name
        define_method(method_name) do |*args|
          git.pull
          plumbing.send(method_name, *args)
        end
      end

      def readwrite method_name
        define_method(method_name) do |*args|
          git.pull
          plumbing.send(method_name, *args)

          git.commit_a args.last
          git.push
        end
      end
    end

    readonly :metadata_entries
    readonly :user_entries
    readonly :all_entries
    readonly :projects
    readonly :members
    readwrite :add_metadata_entry
    readwrite :add_user_entry
  end
end
