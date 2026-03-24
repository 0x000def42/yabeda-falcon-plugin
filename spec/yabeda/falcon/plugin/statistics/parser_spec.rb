require "spec_helper"
require "yabeda/falcon/plugin/statistics"

RSpec.describe Yabeda::Falcon::Plugin::Statistics::Parser do
  subject(:parser) { described_class.new(worker_label: 12345) }

  describe "#parse" do
    context "with valid raw stats" do
      let(:raw_stats) do
        {
          connections_total: 100,
          connections_active: 5,
          requests_total: 200,
          requests_active: 3
        }
      end

      it "returns an array of metric hashes" do
        result = parser.parse(raw_stats)
        expect(result).to contain_exactly(
          { name: :connections_total, labels: { worker: 12345 }, value: 100 },
          { name: :connections_active, labels: { worker: 12345 }, value: 5 },
          { name: :requests_total_count, labels: { worker: 12345 }, value: 200 },
          { name: :requests_active, labels: { worker: 12345 }, value: 3 }
        )
      end
    end

    context "with partial stats" do
      let(:raw_stats) do
        { connections_total: 50 }
      end

      it "returns only metrics with values" do
        result = parser.parse(raw_stats)
        expect(result).to eq([
          { name: :connections_total, labels: { worker: 12345 }, value: 50 }
        ])
      end
    end

    context "with nil stats" do
      it "returns an empty array" do
        expect(parser.parse(nil)).to eq([])
      end
    end

    context "with empty stats" do
      it "returns an empty array" do
        expect(parser.parse({})).to eq([])
      end
    end
  end
end
