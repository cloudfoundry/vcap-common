# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"
require "unit/em_fiber_wrap"

require "vcap/component"

describe VCAP::Component do
  def cleanup
    VCAP::Component.instance_eval do
      if instance_variables.include?(:@varz)
        remove_instance_variable(:@varz)
      end

      if instance_variables.include?(:@healthz)
        remove_instance_variable(:@healthz)
      end
    end
  end

  before do
    config = Steno::Config.new(:context => nil)
    Steno.init(config)
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
    it "throws an exception if no logger is provided as an arg" do
      expect {
        em_fiber_wrap {
          VCAP::Component.register(
            :type => "Component",
            :host => "127.0.0.1",
            :index => 1,
            :nats => nil,
            :port => 8080,
            :user => "user",
            :password => "password"
          )
        }
      }.to raise_error(VCAP::LoggerError)
    end

    it "throws an exception if a Steno logger is not provided as an arg" do
      expect {
        em_fiber_wrap {
          VCAP::Component.register(
            :type => "Component",
            :host => "127.0.0.1",
            :index => 1,
            :nats => nil,
            :port => 8080,
            :user => "user",
            :password => "password",
            :logger => Logger.new(nil)
          )
        }
      }.to raise_error(VCAP::LoggerError)
    end

    it "adds log level stats to the varz" do
      NATS.stub(:subscribe)
      NATS.stub(:publish)

      em_fiber_wrap {
        VCAP::Component.register(
          :type => "Component",
          :host => "127.0.0.1",
          :index => 1,
          :nats => nil,
          :port => 8080,
          :user => "user",
          :password => "password",
          :logger => Steno.logger("test")
        )
      }

      expect(VCAP::Component.varz).to have_key(:log_counts)
      expect(VCAP::Component.varz[:log_counts]).to be_kind_of(VCAP::LogLevelCounts)
    end
  end
end

describe VCAP::LogLevelCounts do
  before do
    config = Steno::Config.new(:context => nil)
    Steno.init(config)
  end

  it "encodes to JSON" do
    expected_hash = {}
    Steno::Logger::LEVELS.each do |level_name, level|
      expected_hash[level_name.to_s] = level.count
    end

    llhash = VCAP::LogLevelCounts.new(Steno.logger("test"))
    output = Yajl::Parser.parse(Yajl::Encoder.encode(llhash))
    expect(output).to eq expected_hash
  end
end

