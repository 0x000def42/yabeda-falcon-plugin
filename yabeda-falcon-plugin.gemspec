require_relative "lib/yabeda/falcon/plugin/version"

Gem::Specification.new do |spec|
  spec.name          = "yabeda-falcon-plugin"
  spec.version       = Yabeda::Falcon::Plugin::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your@email.com"]

  spec.summary       = "Yabeda plugin for Falcon"
  spec.description   = "Yabeda plugin for Falcon web server"
  spec.homepage      = "https://github.com/your/yabeda-falcon-plugin"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = Dir["lib/**/*.rb", "*.gemspec"]
  spec.require_paths = ["lib"]
end
