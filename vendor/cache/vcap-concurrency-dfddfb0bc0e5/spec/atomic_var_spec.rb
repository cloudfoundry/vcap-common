require "spec_helper"

describe VCAP::Concurrency::AtomicVar do
  describe "#value" do
    it "should return the current value" do
      iv = 5
      av = VCAP::Concurrency::AtomicVar.new(iv)
      av.value.should == iv
    end
  end

  describe "#value=" do
    it "should allow the current value to be changed" do
      av = VCAP::Concurrency::AtomicVar.new(1)
      nv = 2
      av.value = nv
      av.value.should == nv
    end
  end

  describe "#mutate" do
    it "should update the value to the result of the supplied block" do
      iv = 2
      av = VCAP::Concurrency::AtomicVar.new(iv)
      av.mutate { |v| v * v }
      av.value.should == (iv * iv)
    end
  end

  describe "#wait_value_changed" do
    it "should return immediately if the current value differs from the supplied value" do
      iv = 1
      av = VCAP::Concurrency::AtomicVar.new(iv)
      av.wait_value_changed(2).should == iv
    end

    it "should block if the current value is the same" do
      barrier = VCAP::Concurrency::AtomicVar.new(0)

      # We're using the atomic var as a form of synchronization here.
      t = Thread.new do
        barrier.wait_value_changed(0)

        barrier.mutate { |v| v + 1 }
      end

      cur_val = barrier.mutate { |v| v + 1 }

      barrier.wait_value_changed(cur_val)

      t.join

      barrier.value.should == 2
    end
  end
end
