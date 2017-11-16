require 'date'

module Tempos
  module Reports
    class Daily < Struct.new(:plumbing)
      def reduce project_identifier
        r = plumbing.
          all_entries(project_identifier).
          reduce({ranges: [], started: {} }) do |report, entry|
            case entry[2]
            when "start"
              report.merge(
                started: report[:started].merge(entry.last => Integer(entry[0])),
              )
            when "stop"
              report.merge(
                ranges: report[:ranges] + [[report[:started][entry.last], Integer(entry[0]), entry.last] ],
                started: report[:started].reject { |key| key == entry.last },
              )
            when "add"
              report.merge(
                ranges: report[:ranges] + [[Integer(entry[0]), Integer(entry[0]) + Integer(entry[3]), entry.last]],
              )

            when "remove"
              report.merge(
                ranges: report[:ranges] + [[Integer(entry[0]), Integer(entry[0]) - Integer(entry[3]), entry.last]],
              )
            end
        end[:ranges].map do |e|
          [Time.at(e[0]), Time.at(e[1]), e[2]]
        end

        (
          r.map(&:first).min.to_date ..
          r.map { |e| e[1] }.max.to_date
        ).map do |day|
          [
            day,
            r.map do |e|
              [
                clamp(e[1], day.to_time, (day+1).to_time) -
                clamp(e[0], day.to_time, (day+1).to_time),
                e[2],
              ]
            end.
            group_by(&:last).
            transform_values { |es| es.map(&:first).sum }
          ]
        end.to_h
      end

      def clamp value, min, max
        [[value, min].max, max].min
      end
    end
  end
end
