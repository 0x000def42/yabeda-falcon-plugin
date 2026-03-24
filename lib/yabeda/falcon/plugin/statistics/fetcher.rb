module Yabeda
  module Falcon
    module Plugin
      module Statistics
        class Fetcher
          def initialize(registry)
            @registry = registry
          end

          def fetch
            return {} unless @registry

            @registry.values
          end
        end
      end
    end
  end
end
