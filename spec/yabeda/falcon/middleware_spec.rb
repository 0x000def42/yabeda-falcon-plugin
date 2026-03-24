require "spec_helper"
require "rack/test"
require "yabeda/falcon/middleware"

RSpec.describe Yabeda::Falcon::Middleware do
  include Rack::Test::Methods

  before { Yabeda::Falcon::Plugin.install! }

  let(:inner_app) do
    ->(env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
  end

  let(:app) { described_class.new(inner_app) }

  describe "request metrics" do
    it "increments falcon_http_requests_total with correct labels" do
      get "/users"
      get "/users"
      value = Yabeda.falcon_http_requests_total.values[{ method: "GET", path: "/users", status: "200" }]
      expect(value.value).to eq(2)
    end

    it "records falcon_http_request_duration" do
      get "/users"
      expect(Yabeda.falcon_http_request_duration.values).to have_key({ method: "GET", path: "/users", status: "200" })
    end

    it "uses the response status in labels" do
      not_found_app = ->(env) { [404, {}, ["Not Found"]] }
      app = described_class.new(not_found_app)
      get_with_app(app, "/missing")
      expect(Yabeda.falcon_http_requests_total.values).to have_key({ method: "GET", path: "/missing", status: "404" })
    end
  end

  describe "path normalization" do
    it "collapses numeric path segments to :id" do
      get "/users/42"
      expect(Yabeda.falcon_http_requests_total.values).to have_key({ method: "GET", path: "/users/:id", status: "200" })
    end

    it "collapses nested numeric segments" do
      get "/orgs/7/repos/99"
      expect(Yabeda.falcon_http_requests_total.values).to have_key({ method: "GET", path: "/orgs/:id/repos/:id", status: "200" })
    end

    it "accepts a custom path_labeler" do
      custom_app = described_class.new(inner_app, path_labeler: ->(_env) { "/custom" })
      get_with_app(custom_app, "/whatever/123")
      expect(Yabeda.falcon_http_requests_total.values).to have_key({ method: "GET", path: "/custom", status: "200" })
    end
  end

  describe "exception handling" do
    it "records status 500 and re-raises on exception" do
      boom_app = ->(env) { raise "boom" }
      boom_middleware = described_class.new(boom_app)

      expect { get_with_app(boom_middleware, "/crash") }.to raise_error("boom")
      expect(Yabeda.falcon_http_requests_total.values).to have_key({ method: "GET", path: "/crash", status: "500" })
    end
  end

  private

  def get_with_app(custom_app, path)
    mock_env = Rack::MockRequest.env_for(path, method: "GET")
    custom_app.call(mock_env)
  rescue StandardError
    raise
  end
end
