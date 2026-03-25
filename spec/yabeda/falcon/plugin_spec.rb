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

    it "registers scheduler gauges" do
      expect(Yabeda.falcon_scheduler_load).to be_a(Yabeda::Gauge)
      expect(Yabeda.falcon_scheduler_tasks).to be_a(Yabeda::Gauge)
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

  describe ".install! container metrics" do
    let(:restart_rate) { double(per_second: 0.5) }
    let(:failure_rate) { double(per_second: 0.1) }
    let(:mock_stats) do
      instance_double("Async::Container::Statistics",
        spawns: 3, restarts: 2, failures: 1,
        restart_rate: restart_rate, failure_rate: failure_rate)
    end

    context "when container_statistics is provided" do
      before { described_class.install!(container_statistics: mock_stats) }

      it "registers all 5 container gauges" do
        expect(Yabeda.falcon_container_worker_spawns).to be_a(Yabeda::Gauge)
        expect(Yabeda.falcon_container_worker_restarts).to be_a(Yabeda::Gauge)
        expect(Yabeda.falcon_container_worker_failures).to be_a(Yabeda::Gauge)
        expect(Yabeda.falcon_container_worker_restart_rate).to be_a(Yabeda::Gauge)
        expect(Yabeda.falcon_container_worker_failure_rate).to be_a(Yabeda::Gauge)
      end

      it "collects spawns during Yabeda.collect!" do
        Yabeda.collect!
        expect(Yabeda.falcon_container_worker_spawns.values[{}].value).to eq(3)
      end

      it "collects restarts during Yabeda.collect!" do
        Yabeda.collect!
        expect(Yabeda.falcon_container_worker_restarts.values[{}].value).to eq(2)
      end

      it "collects failures during Yabeda.collect!" do
        Yabeda.collect!
        expect(Yabeda.falcon_container_worker_failures.values[{}].value).to eq(1)
      end

      it "collects restart_rate during Yabeda.collect!" do
        Yabeda.collect!
        expect(Yabeda.falcon_container_worker_restart_rate.values[{}].value).to eq(0.5)
      end

      it "collects failure_rate during Yabeda.collect!" do
        Yabeda.collect!
        expect(Yabeda.falcon_container_worker_failure_rate.values[{}].value).to eq(0.1)
      end
    end

    context "when container_statistics is nil" do
      before { described_class.install! }

      it "does not error on collect" do
        expect { Yabeda.collect! }.not_to raise_error
      end
    end
  end

  describe ".install! scheduler metrics" do
    let(:mock_children) { double(size: 5) }
    let(:mock_scheduler) { double(load: 0.42, children: mock_children) }

    before do
      allow(Fiber).to receive(:scheduler).and_return(mock_scheduler)
      described_class.install!
    end

    it "collects scheduler_load from Fiber.scheduler" do
      Yabeda.collect!
      expect(Yabeda.falcon_scheduler_load.values[{ worker: Process.pid }].value).to eq(0.42)
    end

    it "collects scheduler_tasks from Fiber.scheduler.children.size" do
      Yabeda.collect!
      expect(Yabeda.falcon_scheduler_tasks.values[{ worker: Process.pid }].value).to eq(5)
    end
  end
end
