require 'nats/client'

module CfMessageBus
  class MessageBusFactory
    def self.message_bus(uri)
      ::NATS.connect(uri: uri, max_reconnect_attempts: Float::INFINITY)
    end
  end
end