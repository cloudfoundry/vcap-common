require "eventmachine"
require "steno"
require "securerandom"
require "cf_message_bus/message_bus"

module Cf
  class Registrar
    DISCOVER_TOPIC = "vcap.component.discover"
    ANNOUNCE_TOPIC = "vcap.component.announce"
    ROUTER_START_TOPIC = "router.start"
    ROUTER_GREET_TOPIC = "router.greet"
    ROUTER_REGISTER_TOPIC = "router.register"
    ROUTER_UNREGISTER_TOPIC = "router.unregister"

    attr_reader :logger, :message_bus_uri, :type, :host, :port,
                :username, :password, :uri, :tags, :uuid, :index, :private_instance_id

    def initialize(config)
      @logger = Steno.logger("cf.registrar")

      config = symbolize_keys(config)

      @message_bus_uri = config[:mbus]
      @host = config[:host]
      @port = config[:port]
      @uri = config[:uri]
      @tags = config[:tags]
      @index = config[:index] || 0
      @private_instance_id = config[:private_instance_id]

      if config[:varz]
        @type = config[:varz][:type]
        @username = config[:varz][:username]
        @password = config[:varz][:password]
        @uuid = config[:varz][:uuid] || SecureRandom.uuid
      end
    end

    def register_varz_credentials
      discover_msg = {
        :type => type,
        :host => "#{host}:#{port}",
        :index => index,
        :uuid => "#{index}-#{uuid}",
        :credentials => [username, password]
      }

      if username.nil? || password.nil?
        logger.error("Could not register nil varz credentials")
      else
        logger.info("Connected to NATS - varz registration")

        message_bus.subscribe(DISCOVER_TOPIC) do |_, reply|
          logger.debug("Received #{DISCOVER_TOPIC} publishing #{reply.inspect} #{discover_msg.inspect}")
          message_bus.publish(reply, discover_msg)
        end

        logger.info("Announcing start up #{ANNOUNCE_TOPIC}")
        message_bus.publish(ANNOUNCE_TOPIC, discover_msg)
      end
    end

    def register_with_router
      logger.info("Connected to NATS - router registration")

      message_bus.subscribe(ROUTER_START_TOPIC) do |message|
        handle_router_greeting(message)
      end

      message_bus.request(ROUTER_GREET_TOPIC) do |message|
        handle_router_greeting(message)
      end

      send_registration_message
    end

    def shutdown(&block)
      send_unregistration_message(&block)
    end

    private
    def handle_router_greeting(message)
      send_registration_message

      # bug in mock_message_bus.rb that to_s on the key that causes this to fail when :minimumRegisterIntervalInSeconds
      if (interval = message['minimumRegisterIntervalInSeconds'])
        setup_interval(interval)
      end
    end

    def message_bus
      @message_bus ||= CfMessageBus::MessageBus.new(
        uri: message_bus_uri,
        logger: logger)
    end

    def send_registration_message
      logger.debug("Sending registration: #{registry_message}")
      message_bus.publish(ROUTER_REGISTER_TOPIC, registry_message)
    end

    def send_unregistration_message(&block)
      logger.info("Sending unregistration: #{registry_message}")
      message_bus.publish(ROUTER_UNREGISTER_TOPIC, registry_message, &block)
    end
    
    def registry_message
      {
        :host => host,
        :port => port,
        :uris => Array(uri),
        :tags => tags,
        :index => index,
        :private_instance_id => private_instance_id
      }
    end

    def setup_interval(interval)
      EM.cancel_timer(@registration_timer) if @registration_timer

      @registration_timer = EM.add_periodic_timer(interval) do
        send_registration_message
      end
    end

    def symbolize_keys(hash)
      return hash unless hash.is_a? Hash
      Hash[
        hash.each_pair.map do |k, v|
            [k.to_sym, symbolize_keys(v)]
        end
      ]
    end
  end
end
