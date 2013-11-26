# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"

require "vcap/component"

describe VCAP::Component do

  let(:nats) do
    nats_mock = double("nats")
    nats_mock.stub(:subscribe)
    nats_mock.stub(:publish)
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

  before do
    cleanup
  end

  after do
    cleanup
  end

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
    it "adds log_counter to varz when passed as an option" do
      EventMachine.stub(:reactor_running?).and_return(true)
      VCAP::Component.stub(:start_http_server)

      foo = Object.new
      options = {:log_counter => foo, :nats => nats}
      VCAP::Component.register(options)
      expect(VCAP::Component.varz[:log_counts]).to eq foo
    end
  end

  describe '.updated_varz' do
    before do
      EventMachine.stub(:reactor_running?).and_return(true)
      VCAP::Component.stub(:start_http_server)
      VCAP::Component.register(:nats => nats)

      VCAP::Stats.stub(
        :process_memory_and_cpu => [55792, 12],
        :memory_used_bytes => 2399141888,
        :memory_free_bytes => 6189744128,
        :cpu_load_average => 24
      )
    end

    it 'includes memory/cpu/avg cpu load information' do
      expect(VCAP::Component.updated_varz[:mem]).to eq 55792
      expect(VCAP::Component.updated_varz[:cpu].should).to eq 12
      expect(VCAP::Component.updated_varz[:cpu_load_avg]).to eq 24
      expect(VCAP::Component.updated_varz[:mem_used_bytes]).to eq 2399141888
      expect(VCAP::Component.updated_varz[:mem_free_bytes]).to eq 6189744128
    end
  end
end
