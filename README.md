# yabeda-falcon-plugin

A [Yabeda](https://github.com/yabeda-rb/yabeda) metrics plugin for the [Falcon](https://github.com/socketry/falcon) web server.

Collects per-request and server-level metrics via a Rack middleware and an async background collector.

## Installation

Add to your Gemfile:

```ruby
gem "yabeda-falcon-plugin"
gem "yabeda-prometheus" # or any other Yabeda adapter
```

## Usage

### config.ru

```ruby
require "yabeda/falcon/plugin"
require "yabeda/falcon/middleware"

Yabeda::Falcon::Plugin.install!

use Yabeda::Falcon::Middleware
run MyApp
```

### Background gauge collection (falcon.rb)

For push-based adapters or periodic `active_connections` gauge updates, start the async collector from a supervised Falcon service:

```ruby
# falcon.rb
load :rack, :self_signed_tls

rack "config.ru"

service "yabeda-metrics-collector" do
  run do
    require "yabeda/falcon/collector"
    Async do
      Yabeda::Falcon::Plugin.collector.start(interval: 15)
    end
  end
end
```

### Custom path normalization

By default, numeric path segments are collapsed to `:id` (e.g. `/users/42` → `/users/:id`). You can override this:

```ruby
use Yabeda::Falcon::Middleware, path_labeler: ->(env) {
  env["PATH_INFO"].gsub(/\/[0-9a-f-]{36}/, "/:uuid")
}
```

## Metrics

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `falcon_requests_total` | Counter | `method`, `path`, `status` | Total requests handled |
| `falcon_request_duration` | Histogram | `method`, `path`, `status` | Request duration in seconds |
| `falcon_active_connections` | Gauge | `worker` | Active connections per worker PID |

## Multi-process note

Falcon runs multiple worker processes when using `falcon serve -n N`. Each worker independently tracks its own `falcon_active_connections` gauge, labeled by `worker: Process.pid`. Request counters and histograms are also per-worker.

For aggregation across workers, use a push-based setup:
- **[prometheus_exporter](https://github.com/discourse/prometheus_exporter)** — workers push to a sidecar exporter process
- **[yabeda-statsd](https://github.com/yabeda-rb/yabeda-statsd)** — each worker pushes to StatsD; aggregation happens at the StatsD/Graphite/DataDog layer

## License

MIT
