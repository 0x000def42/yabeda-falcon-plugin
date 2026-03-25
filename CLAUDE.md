# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby gem (`yabeda-falcon-plugin`) providing Yabeda metrics integration for the Falcon web server. Collects per-request HTTP metrics via Rack middleware and server-level metrics from Falcon's `async-utilization` registry.

## Commands

```bash
bundle install                                    # Install dependencies
bundle exec rspec                                 # Run all tests
bundle exec rspec spec/yabeda/falcon/middleware_spec.rb  # Run a single spec file
gem build yabeda-falcon-plugin.gemspec             # Build the gem
bundle exec irb -r ./lib/yabeda/falcon/plugin      # Interactive console
```

Default rake task is `spec`, so `bundle exec rake` also runs tests.

## Architecture

The gem has two metric collection layers:

**Per-request metrics** — `Yabeda::Falcon::Middleware` is Rack middleware that wraps each request, measuring duration and recording counter/histogram metrics. It normalizes URL paths (numeric segments → `:id`) and supports custom path labelers via constructor argument.

**Server-level metrics** — `Yabeda::Falcon::Plugin::Statistics` registers gauge metrics from Falcon's utilization registry, using a Fetcher/Parser pipeline:
- `Statistics::Fetcher` — retrieves raw stats from `Async::Utilization::Registry`
- `Statistics::Parser` — maps registry keys to metric names, attaches worker (PID) labels
- `Statistics` — registers gauges with Yabeda and sets values during collection

**Entry point** — `Yabeda::Falcon::Plugin.install!(registry: nil)` wires everything together: registers all metrics via `Yabeda.configure` blocks and sets up the collect callback.

## Key Dependencies

- **yabeda** (>= 0.10) — metrics framework
- **rack** (>= 2.0) — middleware interface
- **async-utilization** (>= 0.1) — Falcon server stats registry

## Testing

RSpec with `rack-test`. The spec helper resets Yabeda state before each test. Tests mock `Async::Utilization::Registry` rather than requiring a running Falcon instance.
