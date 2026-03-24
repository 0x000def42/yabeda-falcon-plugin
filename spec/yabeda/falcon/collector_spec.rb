require "spec_helper"
require "yabeda/falcon/collector"

RSpec.describe Yabeda::Falcon::Collector do
  subject(:collector) { described_class.new }

  before { Yabeda::Falcon::Plugin.install! }

  describe "#active_connections" do
    it "starts at zero" do
      expect(collector.active_connections).to eq(0)
    end
  end

  describe "#increment / #decrement" do
    it "tracks increments" do
      collector.increment
      collector.increment
      expect(collector.active_connections).to eq(2)
    end

    it "tracks decrements" do
      collector.increment
      collector.increment
      collector.decrement
      expect(collector.active_connections).to eq(1)
    end

    it "does not go below zero" do
      collector.decrement
      expect(collector.active_connections).to eq(0)
    end
  end

  describe "#record_gauges" do
    it "sets falcon_active_connections gauge for current PID" do
      collector.increment
      collector.record_gauges
      expect(Yabeda.falcon_active_connections.values[{ worker: Process.pid }]).to eq(1)
    end
  end
end
