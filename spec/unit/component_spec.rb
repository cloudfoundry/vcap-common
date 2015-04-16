require "spec_helper"
require "vcap/component"

describe VCAP::Component do
  let(:nats) do
    nats_mock = double("nats")
    nats_mock.stub(:subscribe)
    nats_mock
  end

  def cleanup
    VCAP::Component.instance_eval do
      if instance_variables.include?(:@varz)
        remove_instance_variable(:@varz)
      end

      if instance_variables.include?(:@healthz)
        remove_instance_variable(:@healthz)
      end

      if instance_variables.include?(:@last_varz_update)
        remove_instance_variable(:@last_varz_update)
      end
    end
  end

  before { cleanup }
  after { cleanup }

  describe "regular #varz" do
    it "should not raise on get" do
      expect do
        VCAP::Component.varz[:foo]
      end.to_not raise_error
    end
  end

  describe "thread-safe #varz" do
    before do
      VCAP::Component.varz.threadsafe!
    end

    it "should raise on get when the lock is not held" do
      expect do
        VCAP::Component.varz[:foo]
      end.to raise_error(/lock/i)
    end

    it "should not raise on get when the lock is held" do
      VCAP::Component.varz.synchronize do
        expect do
          VCAP::Component.varz[:foo]
        end.to_not raise_error
      end
    end
  end

  describe "register" do
    before do
      EventMachine.stub(:reactor_running?).and_return(true)
      VCAP::Component.stub(:start_http_server)
    end

    it "adds log_counter to varz when passed as an option" do
      allow(nats).to receive(:publish).with(any_args)
      foo = Object.new
      options = {:log_counter => foo, :nats => nats}
      VCAP::Component.register(options)
      expect(VCAP::Component.varz[:log_counts]).to eq foo
    end

    context "when job_name is specified" do
      it "includes job_name in message" do
        allow(Time).to receive(:now) { '2015-04-16 13:32:22 +0200' }
        discover = {
          :type => nil,
          :index => nil,
          :uuid => 'uuid',
          :host => "host:port",
          :credentials => [ 'uuid', 'uuid' ],
          :start => Time.now,
          :job_name => 'jobname'
        }
        allow(VCAP).to receive(:secure_uuid) { 'uuid'}
        options = {:nats => nats, :host => 'host', :port => 'port', :job_name => 'jobname'}
        expect(nats).to receive(:publish).with(anything, discover.to_json)
        VCAP::Component.register(options)
      end
    end

    context "when job_name is not specified" do
      it "does not include job_name in message" do
        allow(Time).to receive(:now) { '2015-04-16 13:32:22 +0200' }
        discover = {
          :type => nil,
          :index => nil,
          :uuid => 'uuid',
          :host => "host:port",
          :credentials => [ 'uuid', 'uuid' ],
          :start => Time.now
        }
        allow(VCAP).to receive(:secure_uuid) { 'uuid'}
        options = {:nats => nats, :host => 'host', :port => 'port'}
        expect(nats).to receive(:publish).with(anything, discover.to_json)
        VCAP::Component.register(options)
      end
    end
  end

  describe '.updated_varz' do
    before do
      VCAP::Component.varz[:start] = Time.now

      VCAP::Stats.stub(
        :process_memory_bytes_and_cpu => [1024, 12],
        :memory_used_bytes => 2399141888,
        :memory_free_bytes => 6189744128,
        :cpu_load_average => 24,
      )
    end

    it 'includes memory/cpu/avg cpu load information' do
      expect(VCAP::Component.updated_varz[:cpu].should).to eq 12
      expect(VCAP::Component.updated_varz[:cpu_load_avg]).to eq 24
      expect(VCAP::Component.updated_varz[:mem_bytes]).to eq 1024
      expect(VCAP::Component.updated_varz[:mem_used_bytes]).to eq 2399141888
      expect(VCAP::Component.updated_varz[:mem_free_bytes]).to eq 6189744128
    end
  end
end
