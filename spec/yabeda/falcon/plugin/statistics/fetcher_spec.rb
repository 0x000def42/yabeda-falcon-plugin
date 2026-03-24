require "spec_helper"
require "yabeda/falcon/plugin/statistics/fetcher"

RSpec.describe Yabeda::Falcon::Plugin::Statistics::Fetcher do
  describe "#fetch" do
    context "when registry is present" do
      let(:registry) do
        instance_double("Async::Utilization::Registry", values: {
          connections_total: 100,
          connections_active: 5,
          requests_total: 200,
          requests_active: 3
        })
      end

      subject(:fetcher) { described_class.new(registry) }

      it "returns the registry values" do
        expect(fetcher.fetch).to eq({
          connections_total: 100,
          connections_active: 5,
          requests_total: 200,
          requests_active: 3
        })
      end
    end

    context "when registry is nil" do
      subject(:fetcher) { described_class.new(nil) }

      it "returns an empty hash" do
        expect(fetcher.fetch).to eq({})
      end
    end
  end
end
