# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"

require "vcap/component"

describe VCAP::Component do

  let(:nats) do
    nats_mock = mock("nats")
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
      stub_const('VCAP::WINDOWS', true)
      EventMachine.stub(:reactor_running?).and_return(true)
      VCAP::Component.stub(:start_http_server)
      VCAP::Component.register(:nats => nats)
      Process.stub(pid: 9999)
    end

    let(:task_list) {
      'ruby.exe                       416 Console                    1     55,792 K'
    }

    let(:process_time) {
      <<TIME

"(PDH-CSV 4.0)","\\MACHINE\Process(rubymine)\% processor time"
"09/19/2013 15:41:35.540","12.000000"

The command completed successfully.
TIME
    }

    let(:process_list) {
      <<LIST

"(PDH-CSV 4.0)","\\MACHINE\Process(rubymine)\ID Process"
"09/19/2013 15:38:46.438","9999.000000"

The command completed successfully.
LIST
    }

    it 'includes memory/cpu information' do
      VCAP::Component.should_receive(:'`').with('tasklist /nh /fi "pid eq 9999"').and_return(task_list)
      VCAP::Component.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\ID Process"').and_return(process_list)
      VCAP::Component.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\% processor time"').and_return(process_time)

      expect(VCAP::Component.updated_varz[:mem]).to eq 55792
      expect(VCAP::Component.updated_varz[:cpu].should).to eq 12
    end
  end
end
