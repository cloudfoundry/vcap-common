require "cf_message_bus/version"

module CfMessageBus
  class << self
    def mock!
      @mocked = true
    end

    def unmock!
      @mocked = false
      @mocked_bus = nil
    end

    def make_message_bus(*args)
      if @mocked
        require 'cf_message_bus/mock_message_bus'
        @mocked_bus = MockMessageBus.new(*args)
      else
        require 'cf_message_bus/message_bus'
        MessageBus.new(*args)
      end
    end

    def mocked_message_bus
      @mocked_bus
    end
  end
end
