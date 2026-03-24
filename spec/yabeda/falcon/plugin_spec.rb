require "spec_helper"

RSpec.describe Yabeda::Falcon::Plugin do
  before { described_class.install! }

  describe ".install!" do
    it "registers falcon_requests_total as a counter" do
      expect(Yabeda.falcon_requests_total).to be_a(Yabeda::Counter)
    end

    it "registers falcon_request_duration as a histogram" do
      expect(Yabeda.falcon_request_duration).to be_a(Yabeda::Histogram)
    end

    it "registers falcon_active_connections as a gauge" do
      expect(Yabeda.falcon_active_connections).to be_a(Yabeda::Gauge)
    end
  end

  describe ".collector" do
    it "returns a Collector instance" do
      expect(described_class.collector).to be_a(Yabeda::Falcon::Collector)
    end

    it "returns the same instance on subsequent calls" do
      expect(described_class.collector).to be(described_class.collector)
    end
  end
end
