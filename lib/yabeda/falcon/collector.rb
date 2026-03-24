require "async"
require "yabeda"

module Yabeda
  module Falcon
    class Collector
      def initialize
        @active_connections = 0
      end

      def increment
        @active_connections += 1
      end

      def decrement
        @active_connections -= 1
        @active_connections = 0 if @active_connections < 0
      end

      def active_connections
        @active_connections
      end

      # Start a recurring Async::Task that calls Yabeda.collect! on the given interval.
      # Must be called from within a running Async event loop.
      def start(interval: 15)
        Async do |task|
          loop do
            task.sleep(interval)
            record_gauges
            Yabeda.collect!
          rescue => e
            Console.logger.error(self, e)
          end
        end
      end

      def record_gauges
        Yabeda.falcon_active_connections.set({ worker: Process.pid }, @active_connections)
      end
    end
  end
end
