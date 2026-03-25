require "yabeda"
require_relative "statistics/fetcher"
require_relative "statistics/parser"

module Yabeda
  module Falcon
    module Plugin
      module Statistics
        METRICS = %i[
          connections_total
          connections_active
          requests_total_count
          requests_active
        ].freeze

        METRIC_COMMENTS = {
          connections_total: "Total number of connections accepted by Falcon",
          connections_active: "Number of currently active connections",
          requests_total_count: "Total number of requests handled by Falcon server",
          requests_active: "Number of currently in-flight requests"
        }.freeze

        SCHEDULER_METRICS = {
          scheduler_load: "Async scheduler load (0.0 = idle, 1.0 = fully loaded)",
          scheduler_tasks: "Number of top-level async tasks running in this worker"
        }.freeze

        def self.register_metrics!
          Yabeda.configure do
            group :falcon do
              Statistics::METRICS.each do |metric_name|
                gauge metric_name,
                  tags: %i[worker],
                  comment: Statistics::METRIC_COMMENTS[metric_name]
              end

              Statistics::SCHEDULER_METRICS.each do |metric_name, comment|
                gauge metric_name,
                  tags: %i[worker],
                  comment: comment
              end
            end
          end
        end

        def self.collect!(stats)
          stats.each do |stat|
            Yabeda.public_send(:"falcon_#{stat[:name]}").set(stat[:labels], stat[:value])
          end
        end
      end
    end
  end
end
