require "set"

require "spec_helper"

$stdout.sync = true

describe VCAP::Concurrency::ThreadPool do
  describe "#start" do
    it "should raise an error if it has already been started or stopped" do
      tp = VCAP::Concurrency::ThreadPool.new(1)
      tp.start

      # Started
      expect do
        tp.start
      end.to raise_error(/invalid state/i)

      # Stopped
      tp.stop
      expect do
        tp.start
      end.to raise_error(/invalid state/i)
    end

    it "should start the requested number of worker threads" do
      waiting = VCAP::Concurrency::AtomicVar.new(0)
      barrier = Mutex.new
      num_threads = 5
      promises = []
      tp = VCAP::Concurrency::ThreadPool.new(num_threads)

      # Each worker notifies the main thread that it is ready. When all workers
      # have checked in, the main thread unblocks them all.
      num_threads.times do |ii|
        promises << tp.enqueue do
          waiting.mutate { |v| v + 1 }

          barrier.synchronize {}

          Thread.current
        end
      end

      barrier.lock

      tp.start

      # Wait until all threads have checked in
      wait_threads_active(waiting, num_threads)

      # Let all threads proceed
      barrier.unlock

      # Wait for the threads to finish and collect our result
      results = Set.new(promises.map { |p| p.resolve })

      tp.shutdown

      results.length.should == num_threads
    end
  end

  describe "#enqueue" do
    it "should raise an error if the pool is stopped" do
      tp = VCAP::Concurrency::ThreadPool.new(1)

      tp.stop
      expect do
        tp.enqueue { true }
      end.to raise_error(/invalid state/i)
    end

    it "should be responsible for executing the supplied bock in a worker" do
      tp = VCAP::Concurrency::ThreadPool.new(1)
      expected_result = fib(5)
      promise = tp.enqueue { fib(5) }

      tp.start

      result = promise.resolve

      tp.shutdown

      result.should == expected_result
    end

    it "should propagate exceptions thrown in the block" do
      tp = VCAP::Concurrency::ThreadPool.new(1)
      e = RuntimeError.new("test")
      promise = tp.enqueue { raise e }

      tp.start

      expect do
        promise.resolve
      end.to raise_error(e)

      tp.shutdown
    end
  end

  describe "#stop" do
    it "should allow existing work to be processed" do
      waiting = VCAP::Concurrency::AtomicVar.new(0)
      barrier = Mutex.new
      num_threads = 5
      promises = []
      tp = VCAP::Concurrency::ThreadPool.new(num_threads)

      # Each worker notifies the main thread that it is ready. When all workers
      # have checked in, the main thread unblocks them all.
      num_threads.times do |ii|
        promises << tp.enqueue do
          waiting.mutate { |v| v + 1 }

          barrier.synchronize {}

          ii
        end
      end

      barrier.lock

      tp.start

      # Wait until all threads have checked in
      wait_threads_active(waiting, num_threads)

      # All threads are active here, but cannot proceed until we unlock the
      # barrier. Thus, any work added here must live in the queue.
      num_threads.times do |ii|
        promises << tp.enqueue { ii + num_threads }
      end

      tp.stop

      # Let all threads proceed
      barrier.unlock

      # Wait for the threads to finish and collect our results
      results = promises.map { |p| p.resolve }

      tp.join

      results.length.should == 2 * num_threads
    end
  end

  describe "#join" do
    it "should raise an error unless the pool has been started or stopped" do
      tp = VCAP::Concurrency::ThreadPool.new(5)
      expect do
        tp.join
      end.to raise_error(/invalid state/i)
    end
  end

  def wait_threads_active(counter, expected)
    cur = 0
    done = false
    while (cur = counter.wait_value_changed(cur)) != expected
    end
  end

  def fib(ii)
    case ii
    when 1
      1
    when 0
      1
    else
      fib(ii - 1) + fib(ii - 2)
    end
  end
end
