module VCAP
  module Concurrency
    class Error        < StandardError; end
    class TimeoutError < Error; end
  end
end

