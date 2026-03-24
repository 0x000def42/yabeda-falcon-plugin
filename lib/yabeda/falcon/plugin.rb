require "yabeda"
require_relative "plugin/version"
require_relative "plugin/statistics"

module Yabeda
  module Falcon
    module Plugin
      class << self
        attr_accessor :registry, :fetcher, :parser
      end

      def self.install!(registry: nil)
        @registry = registry
        @fetcher = Statistics::Fetcher.new(registry)
        @parser = Statistics::Parser.new(worker_label: Process.pid)

        Statistics.register_metrics!

        Yabeda.configure do
          group :falcon do
            counter :http_requests_total,
              tags: %i[method path status],
              comment: "Total HTTP requests handled by Falcon"

            histogram :http_request_duration,
              tags: %i[method path status],
              unit: :seconds,
              buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
              comment: "HTTP request duration in seconds"

            collect do
              raw = Yabeda::Falcon::Plugin.fetcher.fetch
              parsed = Yabeda::Falcon::Plugin.parser.parse(raw)
              Statistics.collect!(parsed)
            end
          end
        end

        Yabeda.configure!
      end
    end
  end
end
