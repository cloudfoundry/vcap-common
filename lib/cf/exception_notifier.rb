require "squash/ruby"

module Cf
  class ExceptionNotifier
    class << self
      def setup(squash_config)
        if squash_config && [:api_key, :api_host, :revision].all?{|k| squash_config.keys.include?(k)}
          Squash::Ruby.configure(squash_config)
          @configured = true
        end
      end

      def reset
        @configured = nil
      end

      def notify(ex, user_data={})
        if @configured
          Squash::Ruby.notify(ex, user_data)
        else
          puts "Not alerting exception #{ex} because no exception notification has been configured"
        end
      end
    end
  end
end