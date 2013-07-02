require "spec_helper"

describe VCAP::Concurrency::Proxy do
  describe "#method_missing" do
    it "should proxy method calls to the underlying object" do
      proxied_object = ["hi"]
      proxy = VCAP::Concurrency::Proxy.new(proxied_object)
      proxy << "there"

      proxied_object.should == ["hi", "there"]
    end
  end
end
