# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby gem (`yabeda-falcon-plugin`) providing Yabeda metrics integration for the Falcon web server. Collects per-request HTTP metrics via Rack middleware and server-level metrics from Falcon's `async-utilization` registry.

## Commands

```bash
bundle install                                    # Install dependencies
bundle exec rspec                                 # Run unit tests (integration excluded)
INTEGRATION=1 bundle exec rspec                   # Run all tests including integration
bundle exec rake integration                      # Run integration tests only
bundle exec rspec spec/yabeda/falcon/middleware_spec.rb  # Run a single spec file
gem build yabeda-falcon-plugin.gemspec             # Build the gem
bundle exec irb -r ./lib/yabeda/falcon/plugin      # Interactive console
```

Default rake task is `spec`, so `bundle exec rake` runs unit tests only.

## Architecture

The gem has two metric collection layers:

**Per-request metrics** — `Yabeda::Falcon::Middleware` is Rack middleware that wraps each request, measuring duration and recording counter/histogram metrics. It normalizes URL paths (numeric segments → `:id`) and supports custom path labelers via constructor argument.

**Server-level metrics** — `Yabeda::Falcon::Plugin::Statistics` registers gauges across three sources, all collected via a single `collect` block in the plugin:
- `Statistics::Fetcher` / `Statistics::Parser` — read `Async::Utilization::Registry` keys (`connections_total/active`, `requests_total/active`) and attach a `worker` (PID) label
- Scheduler gauges (`scheduler_load`, `scheduler_tasks`) — read directly from `Fiber.scheduler` in the collect block; no-op when scheduler is nil
- Container gauges (`container_worker_spawns/restarts/failures/restart_rate/failure_rate`) — read from an `Async::Container::Statistics` object when provided; supervisor-level aggregates with no label

**Entry point** — `Yabeda::Falcon::Plugin.install!(registry: nil, container_statistics: nil)` wires everything together. `registry` is the `Async::Utilization::Registry` from the Falcon server; `container_statistics` is optional and only needed when running under `async-container` to expose worker lifecycle metrics (supervisor-side).

## Key Dependencies

- **yabeda** (>= 0.10) — metrics framework
- **rack** (>= 2.0) — middleware interface
- **async-utilization** (>= 0.1) — Falcon server stats registry

## Git Workflow

Always follow this workflow for every task:
1. Pull latest from main and create a new branch before starting work
2. Make changes
3. Commit and push the branch (with `-u`) when done

## Testing

**Unit tests** — RSpec with `rack-test`. The spec helper resets Yabeda state before each test. Tests mock `Async::Utilization::Registry` rather than requiring a running Falcon instance. Tagged specs with `:integration` are excluded by default.

**Integration tests** — Located in `spec/integration/`. A dummy Rack app (`spec/dummy/config.ru`) wires up the full plugin + yabeda-prometheus stack. Tests spawn a real Falcon server process, send HTTP requests, and verify Prometheus metrics on `/metrics`. Run with `INTEGRATION=1 bundle exec rspec` or `bundle exec rake integration`.
