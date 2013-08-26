require "eventmachine"
require "eventmachine/schedule_sync"

describe "EventMachine#schedule_sync" do
  before do
    EM.stub(:schedule).and_yield
  end

  it "should run a block on the reactor thread and return the result" do
    EM.should_receive(:schedule).and_yield
    result = EM.schedule_sync do
      "sync return from the reactor thread"
    end
    result.should == "sync return from the reactor thread"
  end

  it "should run a block that takes the promise" do
    result = EM.schedule_sync do |promise|
      promise.deliver("async return from the reactor thread immediate")
    end
    result.should == "async return from the reactor thread immediate"
  end

  it "should rethrow exceptions in the calling thread" do
    expect {
      EM.schedule_sync do
        raise "blowup"
      end
    }.to raise_error(Exception, /blowup/)
  end
end
