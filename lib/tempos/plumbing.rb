module Tempos
  class Plumbing < Struct.new(:root)
    def metadata_entries project
      entries(project, "metadata").
        sort_by { |line| Integer(line[0]) }
    end

    def user_entries project, username
      entries(project, username).
        map { |line| line + [username] }.
        sort_by { |line| Integer(line[0]) }
    end

    def all_entries project
      members(project).
        flat_map { |member| user_entries(project, member) }.
        +(metadata_entries(project)).
        sort_by { |line| Integer(line[0]) }
    end

    def projects
      Dir[File.join(root, "*", "*")].map do |path|
        path.split("/").last(2).join("/")
      end
    end

    def members project
      Dir[File.join(root, project, "*@*")].map do |path|
        path.split("/").last
      end
    end

    def add_metadata_entry project, timestamp, timezone, command
      add_entry project, "metadata", timestamp, timezone, command
    end

    def add_user_entry project, username, timestamp, timezone, command
      add_entry project, username, timestamp, timezone, command
    end

    private
    def entries project, entry
      (File.readlines(File.join(root, project, entry)) rescue []).
        reject { |line| line.start_with? "#" }.
        reject { |line| line.strip.empty? }.
        map { |line| line.split(/\s+/) }
    end

    def add_entry project, entry, timestamp, timezone, command
      path = File.join(root, project, entry)

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "a") do |file|
        file.puts "#{timestamp} #{timezone} #{command}"
      end
    end
  end
end
