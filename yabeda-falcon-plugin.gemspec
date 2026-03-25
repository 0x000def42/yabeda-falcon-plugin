require_relative "lib/yabeda/falcon/plugin/version"

Gem::Specification.new do |spec|
  spec.name          = "yabeda-falcon-plugin"
  spec.version       = Yabeda::Falcon::Plugin::VERSION
  spec.authors       = ["0x000def42"]
  spec.email         = [""]

  spec.summary       = "Yabeda metrics plugin for the Falcon web server"
  spec.description   = "Collects per-request and server-level metrics from Falcon via Rack middleware and Falcon's async-utilization registry, and exposes them through the Yabeda metrics framework."
  spec.homepage      = "https://github.com/0x000def42/yabeda-falcon-plugin"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files         = Dir["lib/**/*.rb", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "yabeda", ">= 0.10"
  spec.add_dependency "rack", ">= 2.0"
  spec.add_dependency "async-utilization", ">= 0.1"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rack-test", "~> 2.0"
  spec.add_development_dependency "async", "~> 2.0"
  spec.add_development_dependency "falcon", "~> 0.47"
  spec.add_development_dependency "yabeda-prometheus", "~> 0.9"
end
