require "thread"

module VCAP
  module Concurrency
  end
end

# A coarse grained thread-safe proxy object
class VCAP::Concurrency::Proxy
  def initialize(orig)
    @orig = orig
    @lock = Mutex.new
  end

  def method_missing(meth, *args, &blk)
    @lock.synchronize { @orig.send(meth, *args, &blk) }
  end
end
