require "net/http"
require "uri"
require "timeout"

RSpec.describe "Integration: Falcon with yabeda-falcon-plugin", :integration do
  TEST_PORT = ENV.fetch("INTEGRATION_TEST_PORT", 9293).to_i
  BASE_URL  = "http://localhost:#{TEST_PORT}"
  CONFIG_RU = File.expand_path("../dummy/config.ru", __dir__)

  before(:all) do
    @falcon_pid = Process.spawn(
      "bundle", "exec", "falcon", "serve",
      "-b", "http://localhost:#{TEST_PORT}",
      "-n", "1",
      "-c", CONFIG_RU,
      out: File::NULL,
      err: File::NULL
    )

    wait_for_server!
  end

  after(:all) do
    if @falcon_pid
      Process.kill("TERM", @falcon_pid)
      Process.wait(@falcon_pid)
    end
  end

  def http_get(path)
    uri = URI("#{BASE_URL}#{path}")
    Net::HTTP.get_response(uri)
  end

  def wait_for_server!(timeout: 15, interval: 0.5)
    Timeout.timeout(timeout) do
      loop do
        response = Net::HTTP.get_response(URI("#{BASE_URL}/test"))
        break if response.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout
        # Server not ready yet
      ensure
        sleep interval
      end
    end
  rescue Timeout::Error
    raise "Falcon server did not start within #{timeout} seconds"
  end

  def fetch_metrics
    http_get("/metrics").body
  end

  context "per-request metrics" do
    before(:all) do
      3.times { Net::HTTP.get_response(URI("#{BASE_URL}/test")) }
      2.times { Net::HTTP.get_response(URI("#{BASE_URL}/users/42")) }
    end

    it "exposes falcon_http_requests_total counter" do
      body = fetch_metrics
      expect(body).to match(/falcon_http_requests_total\{.*method="GET".*path="\/test".*status="200"/)
    end

    it "counts requests correctly" do
      body = fetch_metrics
      line = body.lines.find { |l| l.include?("falcon_http_requests_total") && l.include?('path="/test"') && l.include?('status="200"') }
      expect(line).not_to be_nil
      count = line.strip.split.last.to_f
      expect(count).to be >= 3.0
    end

    it "normalizes numeric path segments to :id" do
      body = fetch_metrics
      expect(body).to include('path="/users/:id"')
      expect(body).not_to include('path="/users/42"')
    end

    it "exposes falcon_http_request_duration histogram" do
      body = fetch_metrics
      expect(body).to match(/falcon_http_request_duration_seconds_bucket\{/)
      expect(body).to match(/falcon_http_request_duration_seconds_count\{/)
      expect(body).to match(/falcon_http_request_duration_seconds_sum\{/)
    end
  end

  context "404 responses" do
    before(:all) do
      Net::HTTP.get_response(URI("#{BASE_URL}/nonexistent"))
    end

    it "records 404 status in metrics" do
      body = fetch_metrics
      expect(body).to match(/falcon_http_requests_total\{.*status="404"/)
    end
  end

  context "metrics endpoint" do
    it "returns 200 from /metrics" do
      response = http_get("/metrics")
      expect(response.code).to eq("200")
    end

    it "returns prometheus text format content type" do
      response = http_get("/metrics")
      expect(response["content-type"]).to include("text/plain")
    end
  end
end
