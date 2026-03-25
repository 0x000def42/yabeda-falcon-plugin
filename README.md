# yabeda-falcon-plugin

A [Yabeda](https://github.com/yabeda-rb/yabeda) metrics plugin for the [Falcon](https://github.com/socketry/falcon) web server.

Collects per-request HTTP metrics via Rack middleware and server-level metrics from Falcon's [async-utilization](https://github.com/socketry/async-utilization) registry.

## Installation

Add to your Gemfile:

```ruby
gem "yabeda-falcon-plugin"
gem "yabeda-prometheus" # or any other Yabeda adapter
```

## Usage

### Rack application (config.ru)

```ruby
require "yabeda/falcon/plugin"
require "yabeda/falcon/middleware"

Yabeda::Falcon::Plugin.install!

use Yabeda::Falcon::Middleware
run MyApp
```

### Rails application

```ruby
# config/initializers/yabeda.rb
require "yabeda/falcon/plugin"

Yabeda::Falcon::Plugin.install!
```

```ruby
# config/application.rb
config.middleware.use Yabeda::Falcon::Middleware
```

### Server-level metrics

To collect server-level gauges (connections, active requests), pass the Falcon utilization registry. If omitted, only per-request metrics are collected.

```ruby
Yabeda::Falcon::Plugin.install!(registry: Async::Utilization::Registry.default)
```

### Custom path normalization

By default, numeric path segments are collapsed to `:id` (e.g. `/users/42` -> `/users/:id`). You can override this:

```ruby
use Yabeda::Falcon::Middleware, path_labeler: ->(env) {
  env["PATH_INFO"].gsub(/\/[0-9a-f-]{36}/, "/:uuid")
}
```

## Metrics

### Server-level gauges (from Falcon's utilization registry)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `falcon_connections_total` | Gauge | `worker` | Total connections accepted |
| `falcon_connections_active` | Gauge | `worker` | Currently active connections |
| `falcon_requests_total_count` | Gauge | `worker` | Total requests handled by the server |
| `falcon_requests_active` | Gauge | `worker` | Currently in-flight requests |

### Per-request metrics (from Rack middleware)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `falcon_http_requests_total` | Counter | `method`, `path`, `status` | Total HTTP requests handled |
| `falcon_http_request_duration` | Histogram | `method`, `path`, `status` | Request duration in seconds |

## Multi-process note

Falcon runs multiple worker processes when using `falcon serve -n N`. Each worker independently records its own server-level gauges, labeled by `worker: Process.pid`. Per-request counters and histograms are also per-worker.

For aggregation across workers, use a push-based setup:
- **[prometheus_exporter](https://github.com/discourse/prometheus_exporter)** -- workers push to a sidecar exporter process
- **[yabeda-statsd](https://github.com/yabeda-rb/yabeda-statsd)** -- each worker pushes to StatsD; aggregation happens at the StatsD/Graphite/DataDog layer

## License

MIT
