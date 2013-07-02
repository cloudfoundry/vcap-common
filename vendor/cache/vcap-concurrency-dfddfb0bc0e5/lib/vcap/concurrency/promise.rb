require "thread"

require "vcap/concurrency/errors"

module VCAP
  module Concurrency
  end
end

# A promise represents the intent to complete a unit of work at some point
# in the future.
class VCAP::Concurrency::Promise
  def initialize
    @lock   = Mutex.new
    @cond   = ConditionVariable.new
    @done   = false
    @result = nil
    @error  = nil
  end

  # Fulfills the promise successfully. Anyone blocking on the result will be
  # notified immediately.
  #
  # @param  [Object]  result   The result of the associated computation.
  #
  # @return [nil]
  def deliver(result = nil)
    @lock.synchronize do
      assert_not_done

      @result = result
      @done = true

      @cond.broadcast
    end

    nil
  end

  # Fulfills the promise unsuccessfully. Anyone blocking on the result will
  # be notified immediately.
  #
  # NB: The supplied exception will be re raised in the caller of #resolve().
  #
  # @param  [Exception]  The error that occurred while fulfilling the promise.
  #
  # @return [nil]
  def fail(exception)
    @lock.synchronize do
      assert_not_done

      @error = exception
      @done = true

      @cond.broadcast
    end

    nil
  end

  # Waits for the promise to be fulfilled. Blocks the calling thread if the
  # promise has not been fulfilled, otherwise it returns immediately.
  #
  # NB: If the promise failed to be fulfilled, the error that occurred while
  #     fulfilling it will be raised here.
  #
  # @param [Integer] timeout_secs  If supplied, wait for no longer than this
  # value before proceeding. An exception will be raised if the promise hasn't
  # been fulfilled when the timeout occurs.
  #
  # @raise [VCAP::Concurrency::TimeoutError]  Raised if the promise hasn't been
  # fulfilled after +timeout_secs+ seconds since calling resolve().
  #
  # @return [Object]  The result of the associated computation.
  def resolve(timeout_secs = nil)
    @lock.synchronize do
      @cond.wait(@lock, timeout_secs) unless @done

      if !@done
        emsg = "Timed out waiting on result after #{timeout_secs}s."
        raise VCAP::Concurrency::TimeoutError.new(emsg)
      end

      if @error
        raise @error
      else
        @result
      end
    end
  end

  private

  def assert_not_done
    raise "A promise may only be completed once." if @done
  end
end
