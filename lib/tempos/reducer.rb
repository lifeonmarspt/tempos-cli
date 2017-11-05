module Tempos
  class Reducer < Struct.new(:plumbing)
    class Project < Struct.new(:identifier, :budget, :deadline, :rates, :times, :started)
      def rate_for username
        rates.fetch(username) { rates.fetch(:default, [1, "hours"]) }
      end
    end

    def reduce project_identifier
      plumbing.
        all_entries(project_identifier).
        reduce(Project.new(project_identifier, [0, nil], 0, {}, {}, {})) do |project, entry|
          case entry[2]
          when "start"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates,
              project.times,
              project.started.merge(entry.last => Integer(entry[0])),
            )

          when "stop"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates,
              project.times.merge(
                entry.last => project.times.fetch(entry.last, {}).merge(
                  project.rate_for(entry.last) => Integer(entry[0]) - project.started.fetch(entry.last) + project.times.fetch(entry.last, {}).fetch(project.rate_for(entry.last), 0)
                ),
              ),
              project.started.reject { |key| key == entry.last },
            )

          when "add"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates,
              project.times.merge(
                entry.last => project.times.fetch(entry.last, {}).merge(
                  project.rate_for(entry.last) => Integer(entry[3]) + project.times.fetch(entry.last, {}).fetch(project.rate_for(entry.last), 0),
                )
              ),
              project.started,
            )

          when "remove"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates,
              project.times.merge(
                entry.last => project.times.fetch(entry.last, {}).merge(
                  project.rate_for(entry.last) => -Integer(entry[3]) + project.times.fetch(entry.last, {}).fetch(project.rate_for(entry.last), 0),
                )
              ),
              project.started,
            )

          when "set-rate"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates.merge((entry[5] || :default) => [Integer(entry[3]), entry[4]]),
              project.times,
              project.started,
            )

          when "invoice"
            Project.new(
              project_identifier,
              project.budget,
              project.deadline,
              project.rates,
              {},
              project.started,
            )

          when "set-deadline"
            Project.new(
              project_identifier,
              project.budget,
              Integer(entry[3]),
              project.rates,
              project.times,
              project.started,
            )

          when "set-budget"
            Project.new(
              project_identifier,
              [Integer(entry[3]), entry[4]],
              project.deadline,
              project.rates,
              project.times,
              project.started,
            )

          when "add-budget"
            entry[4] == project.budget[1] or raise

            Project.new(
              project_identifier,
              [Integer(entry[3]) + project.budget[0], entry[4]],
              project.deadline,
              project.rates,
              project.times,
              project.started,
            )

          else
            raise entry[2]
          end
        end
    end
  end
end
