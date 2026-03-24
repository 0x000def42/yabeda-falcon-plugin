require "spec_helper"

RSpec.describe Yabeda::Falcon::Plugin do
  describe ".install!" do
    before { described_class.install! }

    it "registers falcon_http_requests_total as a counter" do
      expect(Yabeda.falcon_http_requests_total).to be_a(Yabeda::Counter)
    end

    it "registers falcon_http_request_duration as a histogram" do
      expect(Yabeda.falcon_http_request_duration).to be_a(Yabeda::Histogram)
    end

    it "registers server-level gauges" do
      expect(Yabeda.falcon_connections_total).to be_a(Yabeda::Gauge)
      expect(Yabeda.falcon_connections_active).to be_a(Yabeda::Gauge)
      expect(Yabeda.falcon_requests_total_count).to be_a(Yabeda::Gauge)
      expect(Yabeda.falcon_requests_active).to be_a(Yabeda::Gauge)
    end
  end

  describe ".install! with registry" do
    let(:registry) do
      instance_double("Async::Utilization::Registry", values: {
        connections_total: 10,
        connections_active: 2,
        requests_total: 50,
        requests_active: 1
      })
    end

    before { described_class.install!(registry: registry) }

    it "stores the fetcher" do
      expect(described_class.fetcher).to be_a(Yabeda::Falcon::Plugin::Statistics::Fetcher)
    end

    it "stores the parser" do
      expect(described_class.parser).to be_a(Yabeda::Falcon::Plugin::Statistics::Parser)
    end

    it "collects server metrics via the collect block" do
      Yabeda.collect!
      expect(Yabeda.falcon_connections_total.values[{ worker: Process.pid }].value).to eq(10)
      expect(Yabeda.falcon_requests_active.values[{ worker: Process.pid }].value).to eq(1)
    end
  end

  describe ".install! without registry" do
    before { described_class.install! }

    it "does not error on collect" do
      expect { Yabeda.collect! }.not_to raise_error
    end
  end
end
