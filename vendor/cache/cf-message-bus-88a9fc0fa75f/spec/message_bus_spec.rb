require "cf_message_bus/message_bus"
require "cf_message_bus/message_bus_factory"
require_relative "support/message_bus_behaviors"
require_relative "support/mock_nats"

module CfMessageBus
  describe MessageBus do
    let(:mock_nats) { MockNATS.new }
    let(:bus_uri) { "some message bus uri" }
    let(:bus) { MessageBus.new(uri: bus_uri, logger: logger) }
    let(:logger) { double(:logger, info: nil) }
    let(:fake_promise) { double(:promise) }
    let(:msg) { { foo: "bar" } }
    let(:msg_json) { JSON.dump(msg) }

    before do
      MessageBusFactory.stub(:message_bus).with(bus_uri).and_return(mock_nats)
      EM.stub(:schedule).and_yield
      EM.stub(:defer).and_yield
      EM.stub(:schedule_sync).and_yield(fake_promise)
      bus.stub(:register_cloud_controller)
    end

    it_behaves_like :a_message_bus

    it 'should get the internal message bus from the factory' do
      MessageBusFactory.should_receive(:message_bus).with(bus_uri).and_return(mock_nats)
      MessageBus.new(uri: bus_uri)
    end

    describe 'subscribing' do
      it 'should subscribe on nats and parse json' do
        mock_nats.should_receive(:subscribe).with("foo", {}).and_yield(msg_json, nil)
        bus.subscribe("foo") do |data, inbox|
          data.should == msg
        end
      end

      it 'should handle exceptions in the callback' do
        mock_nats.should_receive(:subscribe).with("foo", {}).and_yield(msg_json, nil)
        logger.should_receive(:error).with(/^exception processing subscription for: 'foo'/)
        bus.subscribe("foo") do |data, inbox|
          raise 'hey guys'
        end
      end

      it 'should handle exceptions in json' do
        mock_nats.should_receive(:subscribe).with("foo", {}).and_yield("not json", nil)
        logger.should_receive(:error).with(/^exception parsing json: 'not json'/)
        bus.subscribe("foo") do |data, inbox|
          data[:error].should == "JSON Parse Error: failed to parse"
        end
      end

      it 'should parse nulls correctly' do
        mock_nats.should_receive(:subscribe).with("foo", {}).and_yield("null", nil)
        logger.should_not_receive(:error)
        bus.subscribe("foo") do |data, inbox|
          expect(data).to be_nil
        end
      end
    end

    describe 'publishing' do
      it 'should publish on nats' do
        mock_nats.should_receive(:publish).with("foo", "bar")
        bus.publish('foo', 'bar')
      end

      it 'should pass a nil message straight through' do
        mock_nats.should_receive(:publish).with("foo", nil)
        bus.publish('foo')
      end

      it 'should dump objects to json' do
        mock_nats.should_receive(:publish).with("foo", JSON.dump('foo' => 'bar'))
        bus.publish('foo', { foo: 'bar' })
      end

      it 'should dump arrays to json' do
        mock_nats.should_receive(:publish).with("foo", JSON.dump(%w[foo bar baz]))
        bus.publish('foo', %w[foo bar baz])
      end

      it 'passes the callback through to nats' do
        mock_nats.should_receive(:publish).with("foo", JSON.dump(%w[foo bar baz])).and_yield
        called = false
        bus.publish('foo', %w[foo bar baz]) do
          called = true
        end
        expect(called).to be_true
      end
    end


    describe 'requesting information' do
      it 'should request on nats and parse json' do
        mock_nats.should_receive(:request).with("foo", nil, {}).and_yield(msg_json, nil)
        bus.request("foo") do |data, _|
          data.should == msg
        end
      end

      it 'should handle exceptions in the callback' do
        mock_nats.should_receive(:request).with("foo", nil, {}).and_yield(msg_json, nil)
        logger.should_receive(:error).with(/^exception processing response for: 'foo'/)
        bus.request("foo") do |data, inbox|
          raise 'hey guys'
        end
      end

      it 'should handle exceptions in json' do
        mock_nats.should_receive(:request).with("foo", nil, {}).and_yield("not json", nil)
        logger.should_receive(:error).with(/^exception parsing json: 'not json'/)
        bus.request("foo") do |data, inbox|
          data[:error].should == "JSON Parse Error: failed to parse"
        end
      end

      it 'should parse nulls correctly' do
        mock_nats.should_receive(:request).with("foo", nil, {}).and_yield("null", nil)
        logger.should_not_receive(:error)
        bus.request("foo") do |data, inbox|
          expect(data).to be_nil
        end
      end

      it 'should pass a nil message straight through' do
        mock_nats.should_receive(:request).with("foo", nil, {})
        bus.request('foo')
      end

      it 'should dump objects to json' do
        mock_nats.should_receive(:request).with("foo", JSON.dump('foo' => 'bar'), {})
        bus.request('foo', { foo: 'bar' })
      end

      it 'should dump arrays to json' do
        mock_nats.should_receive(:request).with("foo", JSON.dump(%w[foo bar baz]), {})
        bus.request('foo', %w[foo bar baz])
      end
    end

    describe 'requesting information synchronously' do
      let(:msg2) { { baz: 'quux'} }
      let(:msg2_json) { JSON.dump(msg2) }
      it 'should schedule onto the EM loop to make the request' do
        EM.should_receive(:schedule_sync).and_yield(fake_promise)
        mock_nats.should_receive(:request).with('foo', msg_json, max: 1)
        bus.synchronous_request('foo', msg)
      end

      it 'should deliver the promise' do
        mock_nats.stub(:request).and_yield(msg_json, nil)
        fake_promise.should_receive(:deliver).with([msg])
        bus.synchronous_request('foo')
      end

      it 'should dump objects to json' do
        mock_nats.should_receive(:request).with('foo', msg_json, max: 1)
        bus.synchronous_request('foo', foo: 'bar')
      end

      it 'should parse json into objects' do
        mock_nats.should_receive(:request).with('foo', nil, max: 1).and_yield(msg_json, nil)
        fake_promise.should_receive(:deliver).with([{ foo: 'bar' }])
        bus.synchronous_request('foo', nil)
      end

      it 'should wait to deliver the promise if multiple results are expected' do
        mock_nats.should_receive(:request).with('foo', nil, max: 2).and_yield(msg_json, nil).and_yield(msg2_json, nil)
        fake_promise.should_receive(:deliver).with([msg, {baz: 'quux'}])
        bus.synchronous_request('foo', nil, result_count: 2)
      end

      it 'should timeout the request even if we have not gotten all the results' do
        request_stub = mock_nats.stub(:request)
        request_stub.and_return('request_id')
        request_stub.and_yield(msg_json, nil).and_yield(msg2_json, nil)
        mock_nats.should_receive(:timeout).with('request_id', 5, expected: 3).and_yield

        fake_promise.should_receive(:deliver).with([msg, msg2])
        bus.synchronous_request('foo', nil, result_count: 3, timeout: 5)
      end
    end

    context 'unsubscribing' do
      it 'should unsubscribe from the underlying message bus' do
        mock_nats.should_receive(:unsubscribe).with('sub id')
        bus.unsubscribe('sub id')
      end
    end

    context 'after nats comes back up' do
      it 'should resubscribe' do
        bus.subscribe("first")
        bus.subscribe("second")
        bus.subscribe("third")

        mock_nats.should_receive(:subscribe).with("first", {})
        mock_nats.should_receive(:subscribe).with("second", {})
        mock_nats.should_receive(:subscribe).with("third", {})

        mock_nats.reconnect!
      end

      it 'should call the recovery callbacks' do
        callback = double(called: true)
        callback.should_receive(:called)
        bus.recover do
          callback.called
        end

        mock_nats.reconnect!
      end
    end
  end
end
