module CfMessageBus
  class MockNATS
    def start(*args)
      yield
    end

    def connect(*args)
    end

    def subscribe(*args)
    end

    def publish(*args)
    end

    def on_reconnect(&blk)
      (@reconnect_callbacks ||= []) << blk
    end

    def request(*args)
    end

    def timeout(*args)
    end

    def unsubscribe(*args)
    end

    def reconnect!
      Array(@reconnect_callbacks).each { |callback| callback.call }
    end

    def connected?
      true
    end
  end
end
