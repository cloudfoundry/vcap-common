module Grape
  module ErrorFormatter
    module Txt
      class << self

        def call(message, backtrace, options = {}, env = nil)
          result = message.is_a?(Hash) ? MultiJson.dump(message) : message
          if (options[:rescue_options] || {})[:backtrace] && backtrace && ! backtrace.empty?
            result += "\r\n "
            result += backtrace.join("\r\n ")
          end
          result
        end

      end
    end
  end
end
