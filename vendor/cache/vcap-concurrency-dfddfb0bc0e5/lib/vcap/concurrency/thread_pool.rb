require "thread"

require "vcap/concurrency/atomic_var"
require "vcap/concurrency/promise"

module VCAP
  module Concurrency
  end
end

class VCAP::Concurrency::ThreadPool
  STOP_SENTINEL = :stop

  STATE_CREATED = 0
  STATE_STARTED = 1
  STATE_STOPPED = 2

  def initialize(num_threads)
    @num_threads = num_threads
    @threads     = []
    @work_queue  = Queue.new
    @state       = STATE_CREATED
    @pool_lock   = Mutex.new
    @num_active_tasks = VCAP::Concurrency::AtomicVar.new(0)
  end

  # Creates all threads in the pool and starts them. Tasks that were enqueued
  # prior to starting the pool will be processed immediately.
  def start
    @pool_lock.synchronize do

      assert_state_in(STATE_CREATED)

      @num_threads.times do
        @threads << create_worker_thread
      end

      @state = STATE_STARTED
    end

    nil
  end

  # Adds a block that will be executed by a worker thread.
  #
  # @param [Block]  blk  The block to be executed by a worker thread.
  #
  # @return [VCAP::Concurrent::Promise]  The caller of enqueue() may wait for
  #                                      the result of blk by calling resolve()
  def enqueue(&blk)
    @pool_lock.synchronize do
      assert_state_in(STATE_CREATED, STATE_STARTED)

      promise = VCAP::Concurrency::Promise.new

      @work_queue.enq([blk, promise])

      promise
    end
  end

  # Stops the thread pool politely, allowing existing work to be completed.
  def stop
    @pool_lock.synchronize do
      @num_threads.times { @work_queue.enq(STOP_SENTINEL) }

      @state = STATE_STOPPED
    end

    nil
  end

  # Waits for all worker threads to finish executing.
  def join
    @pool_lock.synchronize do
      assert_state_in(STATE_STARTED, STATE_STOPPED)
    end

    @threads.each { |t| t.join }

    nil
  end

  # Queues up sentinel values to notify workers to stop, then waits for them
  # to finish.
  def shutdown
    stop
    join

    nil
  end

  # Returns the number of tasks that are currently running. This is equivalent
  # to the number of active threads.
  #
  # @return [Integer]
  def num_active_tasks
    @num_active_tasks.value
  end

  # Returns the number of tasks waiting to be processed
  #
  # NB: While technically correct, this will include the number of unprocessed
  #     sentinel tasks after stop() is called.
  #
  # @return [Integer]
  def num_queued_tasks
    @work_queue.length
  end

  private

  def do_work # son!
    while (item = @work_queue.deq) != STOP_SENTINEL
      blk, promise = item

      @num_active_tasks.mutate { |v| v + 1 }

      result, error, success = nil, nil, true
      begin
        result = blk.call
      rescue => e
        success = false
        error = e
      end

      # This is intentionally outside of the begin/rescue block above. Errors
      # here are bugs in our code, and shouldn't be propagated back to
      # whomever enqueued the task.
      if success
        promise.deliver(result)
      else
        promise.fail(error)
      end

      @num_active_tasks.mutate { |v| v - 1 }
    end

    nil
  end

  def create_worker_thread
    t = Thread.new { do_work }
    t.abort_on_exception = true

    t
  end

  def assert_state_in(*states)
    raise "Invalid state" unless states.include?(@state)
  end
end
