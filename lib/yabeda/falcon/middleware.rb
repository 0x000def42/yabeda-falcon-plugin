require "yabeda"
require_relative "plugin"

module Yabeda
  module Falcon
    class Middleware
      DEFAULT_PATH_LABELER = ->(env) {
        env["PATH_INFO"].gsub(%r{/\d+(/|$)}, '/\:id\1')
      }

      def initialize(app, path_labeler: DEFAULT_PATH_LABELER)
        @app = app
        @path_labeler = path_labeler
      end

      def call(env)
        collector = Yabeda::Falcon::Plugin.collector
        collector.increment
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        status, headers, body = @app.call(env)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

        labels = {
          method: env["REQUEST_METHOD"],
          path:   @path_labeler.call(env),
          status: status.to_s
        }

        Yabeda.falcon_requests_total.increment(labels)
        Yabeda.falcon_request_duration.measure(labels, elapsed)

        [status, headers, body]
      rescue Exception => e
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        labels = {
          method: env["REQUEST_METHOD"],
          path:   @path_labeler.call(env),
          status: "500"
        }
        Yabeda.falcon_requests_total.increment(labels)
        Yabeda.falcon_request_duration.measure(labels, elapsed)
        raise
      ensure
        collector&.decrement
      end
    end
  end
end
