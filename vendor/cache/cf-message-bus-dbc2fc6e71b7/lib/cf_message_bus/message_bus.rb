require "eventmachine"
require "eventmachine/schedule_sync"
require "cf_message_bus/message_bus_factory"

module CfMessageBus
  class Error < StandardError; end

  class MessageBus
    def initialize(config)
      @logger = config[:logger]
      @internal_bus = MessageBusFactory.message_bus(config[:uri])
      @subscriptions = {}
      @internal_bus.on_reconnect { start_internal_bus_recovery }
      @recovery_callback = lambda {}
    end

    def subscribe(subject, options = {}, &block)
      @subscriptions[subject] = [options, block]

      subscribe_on_reactor(subject, options) do |parsed_data, inbox|
        EM.defer do
          run_handler(block, parsed_data, inbox, subject, 'subscription')
        end
      end
    end

    def publish(subject, message = nil, &callback)
      EM.schedule do
        internal_bus.publish(subject, encode(message), &callback)
      end
    end

    def recover(&block)
      @recovery_callback = block
    end

    def request(subject, data = nil, options = {}, &block)
      response_timeout = options.delete(:timeout)
      result_count = options.delete(:result_count)
      options[:max] = result_count if result_count

      subscription_id = internal_bus.request(subject, encode(data), options) do |payload, inbox|
        process_message(payload, inbox) do |parsed_data, inbox|
          run_handler(block, parsed_data, inbox, subject, 'response')
        end
      end

      if response_timeout
        internal_bus.timeout(subscription_id, response_timeout, expected: result_count || 1) do
          run_handler(block, {timeout: true}, nil, subject, 'timeout')
        end
      end
      subscription_id
    end

    def synchronous_request(subject, data = nil, options = {})
      options[:result_count] ||= 1
      result_count = options[:result_count]

      return [] if result_count <= 0

      EM.schedule_sync do |promise|
        results = []

        request(subject, encode(data), options) do |response|
          if response[:timeout]
            promise.deliver(results)
          else
            results << response
            promise.deliver(results) if results.size == result_count
          end
        end
      end
    end

    def unsubscribe(subscription_id)
      internal_bus.unsubscribe(subscription_id)
    end

    def connected?
      internal_bus.connected?
    end

    private

    attr_reader :internal_bus

    def run_handler(block, parsed_data, inbox, subject, type)
      begin
        block.yield(parsed_data, inbox)
      rescue => e
        @logger.error "exception processing #{type} for: '#{subject}' '#{parsed_data.inspect}' \n#{e.inspect}\n #{e.backtrace.join("\n")}"
      end
    end

    def start_internal_bus_recovery
      EM.defer do
        @logger.info("Reconnected to internal_bus.")

        @recovery_callback.call

        @subscriptions.each do |subject, options|
          @logger.info("Resubscribing to #{subject}")
          subscribe(subject, options[0], &options[1])
        end
      end
    end

    def subscribe_on_reactor(subject, options = {}, &blk)
      EM.schedule do
        internal_bus.subscribe(subject, options) do |msg, inbox|
          process_message(msg, inbox, &blk)
        end
      end
    end

    def process_message(msg, inbox, &block)
      payload = JSON.parse(msg)
      block.yield(payload, inbox)
    rescue => e
      @logger.error "exception parsing json: '#{msg}' '#{e.inspect}'"
      block.yield({error: "JSON Parse Error: failed to parse", exception: e, message: msg}, inbox)
    end

    def encode(message)
      unless message.nil? || message.is_a?(String)
        message = JSON.dump(message)
      end
      message
    end
  end
end
