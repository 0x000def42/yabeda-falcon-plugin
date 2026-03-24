require "yabeda"
require_relative "plugin/version"
require_relative "../falcon/collector"

module Yabeda
  module Falcon
    module Plugin
      def self.collector
        @collector ||= Collector.new
      end

      def self.install!
        Yabeda.configure do
          group :falcon do
            counter :requests_total,
              tags: %i[method path status],
              comment: "Total number of requests handled by Falcon"

            histogram :request_duration,
              tags: %i[method path status],
              unit: :seconds,
              buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
              comment: "Request duration in seconds"

            gauge :active_connections,
              tags: %i[worker],
              comment: "Number of currently active connections per worker"

            collect do
              Yabeda::Falcon::Plugin.collector.record_gauges
            end
          end
        end

        Yabeda.configure!
      end
    end
  end
end
