# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem (`yabeda-falcon-plugin`) that provides a Yabeda metrics plugin for the Falcon web server. The project is in early development — the gem scaffold is in place but no functionality has been implemented yet.

## Commands

```bash
# Install dependencies
bundle install

# Build the gem
gem build yabeda-falcon-plugin.gemspec

# Open an interactive console with the gem loaded
bundle exec irb -r ./lib/yabeda/falcon/plugin
```

No test framework or Rakefile has been set up yet. When tests are added, they should be runnable via `bundle exec rspec` (RSpec is the conventional choice for Yabeda ecosystem gems).

## Architecture

The gem follows the standard Yabeda plugin structure:

- `lib/yabeda/falcon/plugin.rb` — main entry point; defines the `Yabeda::Falcon::Plugin` module
- `lib/yabeda/falcon/plugin/version.rb` — gem version constant (`Yabeda::Falcon::Plugin::VERSION`)

The module namespace `Yabeda::Falcon::Plugin` mirrors the gem name. Yabeda plugins typically register metrics groups, collectors, and adapters with the Yabeda core during gem load. The integration point with Falcon would involve hooking into Falcon's middleware or server lifecycle to collect request/response metrics.

The gemspec currently has placeholder author/email/homepage values that should be updated before publishing.
