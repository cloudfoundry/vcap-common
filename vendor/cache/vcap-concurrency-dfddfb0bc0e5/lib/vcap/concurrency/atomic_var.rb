require "thread"

module VCAP
  module Concurrency
  end
end

# A variable that can be queried and updated atomically.
class VCAP::Concurrency::AtomicVar
  def initialize(initial_value = nil)
    @value = initial_value
    @lock  = Mutex.new
    @cond  = ConditionVariable.new
  end

  # @return [Object]  The value bound to this variable.
  def value
    @lock.synchronize { @value }
  end

  # Blocks the calling thread until the current value is different from the
  # supplied value.
  #
  # @param  [Object]  last_value  This method will return once the current
  #                               value no longer equals last_value.
  #
  # @return [Object]  The new value
  def wait_value_changed(last_value)
    done = false
    result = nil

    while !done
      @lock.synchronize do
        if last_value == @value
          @cond.wait(@lock)
        else
          done = true
          result = @value
        end
      end
    end

    result
  end

  def value=(new_value)
    mutate { |v| new_value }
  end

  # Allows the caller to atomically mutate the current value. The new value
  # will be whatever the supplied block evalutes to.
  #
  # @param [Block]  blk  The block to execute while the lock is held. The
  #                      current value will be passed as the only argument to
  #                      the block.
  #
  # @return [Object]     The result of the block (also the new value bound to
  #                      the var).
  def mutate(&blk)
    @lock.synchronize do
      @value = blk.call(@value)

      @cond.broadcast

      @value
    end
  end
end
