require "bundler/setup"
require "yabeda/prometheus"
require "yabeda/falcon/middleware"
require "yabeda/falcon/plugin"

Yabeda::Falcon::Plugin.install!

app = Rack::Builder.new do
  use Yabeda::Prometheus::Exporter

  use Yabeda::Falcon::Middleware

  run ->(env) {
    case env["PATH_INFO"]
    when "/test"
      [200, { "content-type" => "text/plain" }, ["OK"]]
    when "/users/42"
      [200, { "content-type" => "text/plain" }, ["User 42"]]
    when "/error"
      [500, { "content-type" => "text/plain" }, ["Internal Server Error"]]
    else
      [404, { "content-type" => "text/plain" }, ["Not Found"]]
    end
  }
end

run app
