module Yabeda
  module Falcon
    module Plugin
      module Statistics
        class Parser
          METRIC_KEY_MAP = {
            connections_total: :connections_total,
            connections_active: :connections_active,
            requests_total_count: :requests_total,
            requests_active: :requests_active
          }.freeze

          def initialize(worker_label:)
            @worker_label = worker_label
          end

          def parse(raw_stats)
            return [] if raw_stats.nil? || raw_stats.empty?

            Statistics::METRICS.filter_map do |metric_name|
              registry_key = METRIC_KEY_MAP.fetch(metric_name)
              value = raw_stats[registry_key]
              next unless value

              { name: metric_name, labels: { worker: @worker_label }, value: value }
            end
          end
        end
      end
    end
  end
end
