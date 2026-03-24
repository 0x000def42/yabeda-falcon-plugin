require "spec_helper"
require "yabeda/falcon/plugin/statistics"

RSpec.describe Yabeda::Falcon::Plugin::Statistics do
  describe "METRICS" do
    it "contains the expected metric names" do
      expect(described_class::METRICS).to eq(%i[
        connections_total
        connections_active
        requests_total_count
        requests_active
      ])
    end
  end

  describe ".register_metrics!" do
    before { described_class.register_metrics!; Yabeda.configure! }

    it "registers falcon_connections_total as a gauge" do
      expect(Yabeda.falcon_connections_total).to be_a(Yabeda::Gauge)
    end

    it "registers falcon_connections_active as a gauge" do
      expect(Yabeda.falcon_connections_active).to be_a(Yabeda::Gauge)
    end

    it "registers falcon_requests_total_count as a gauge" do
      expect(Yabeda.falcon_requests_total_count).to be_a(Yabeda::Gauge)
    end

    it "registers falcon_requests_active as a gauge" do
      expect(Yabeda.falcon_requests_active).to be_a(Yabeda::Gauge)
    end
  end

  describe ".collect!" do
    before { described_class.register_metrics!; Yabeda.configure! }

    it "sets gauge values from parsed stats" do
      stats = [
        { name: :connections_total, labels: { worker: 1 }, value: 100 },
        { name: :connections_active, labels: { worker: 1 }, value: 5 }
      ]

      described_class.collect!(stats)

      expect(Yabeda.falcon_connections_total.values[{ worker: 1 }].value).to eq(100)
      expect(Yabeda.falcon_connections_active.values[{ worker: 1 }].value).to eq(5)
    end
  end
end
