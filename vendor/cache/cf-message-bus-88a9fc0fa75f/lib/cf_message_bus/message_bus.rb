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

    def subscribe(subject, opts = {}, &block)
      @subscriptions[subject] = [opts, block]

      subscribe_on_reactor(subject, opts) do |parsed_data, inbox|
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
      internal_bus.request(subject, encode(data), options) do |payload, inbox|
        process_message(payload, inbox) do |parsed_data, inbox|
          run_handler(block, parsed_data, inbox, subject, 'response')
        end
      end
    end

    def synchronous_request(subject, data = nil, opts = {})
      result_count = opts[:result_count] || 1
      timeout = opts[:timeout] || -1

      return [] if result_count <= 0

      response = EM.schedule_sync do |promise|
        results = []

        sid = request(subject, encode(data), max: result_count) do |data|
          results << data
          promise.deliver(results) if results.size == result_count
        end

        if timeout >= 0
          internal_bus.timeout(sid, timeout, expected: result_count) do
            promise.deliver(results)
          end
        end
      end

      response
    end

    def unsubscribe(subscription_id)
      internal_bus.unsubscribe(subscription_id)
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

    def subscribe_on_reactor(subject, opts = {}, &blk)
      EM.schedule do
        internal_bus.subscribe(subject, opts) do |msg, inbox|
          process_message(msg, inbox, &blk)
        end
      end
    end

    def process_message(msg, inbox, &block)
      payload = JSON.parse(msg, symbolize_keys: true)
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
