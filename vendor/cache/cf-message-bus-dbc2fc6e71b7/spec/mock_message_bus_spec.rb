require 'cf_message_bus/mock_message_bus'
require_relative 'support/message_bus_behaviors'

module CfMessageBus
  describe MockMessageBus do
    it_behaves_like :a_message_bus

    let(:bus) { MockMessageBus.new }

    it 'should call subscribers inline' do
      received_data = nil

      bus.subscribe("foo") do |data|
        received_data = data
      end
      expect(received_data).to be_nil

      publish_data = 'bar'
      bus.publish("foo", publish_data)
      expect(received_data).to eql(publish_data)
    end

    it 'should call publish callbacks' do
      called = false
      bus.publish("foo") do
        called = true
      end
      expect(called).to be_true
    end

    it 'should record published messages' do
      bus.publish("foo")
      monkey = lambda { "I'm a monkey block" }
      bus.publish("bar", {baz: :quux}, &monkey)

      expect(bus.published_messages[0]).to eq({subject: "foo", message: nil, callback: nil})
      expect(bus.published_messages[1]).to eq({subject: "bar", message: {baz: :quux}, callback: monkey})
    end

    it 'should record published synchronous messages' do
      response = bus.synchronous_request("foo", {data: 1}, {option: :option})
      expect(response).to be_nil

      bus.respond_to_synchronous_request("foo", {bar: "baz"})
      response = bus.synchronous_request("foo", {data: 2}, {option: :option})
      expect(response).to eq("bar" => "baz")

      expect(bus.published_synchronous_messages).to eq([
        {subject: "foo", data: {data: 1}, options: {option: :option}},
        {subject: "foo", data: {data: 2}, options: {option: :option}}
      ])

      expect(bus).to have_requested_synchronous_messages("foo", {data: 1}, {option: :option})
    end

    it 'should clear published messages when asked' do
      bus.publish("foo")
      monkey = lambda { "I'm a monkey block" }
      bus.publish("bar", {baz: :quux}, &monkey)

      bus.clear_published_messages

      expect(bus.published_messages).to be_empty
    end

    it 'should report if a particular subject has been published' do
      bus.publish("foo")
      expect(bus).to have_published("foo")
      expect(bus).not_to have_published("bar")
    end

    it 'should report if a particular subject has been published with the specified message' do
      bus.publish('foo', {bar: 'baz'})
      expect(bus).to have_published_with_message('foo', {bar: 'baz'})
      expect(bus).not_to have_published_with_message('foo', 'umbrella')
    end

    it 'should stringify keys to the subscriber' do
      received_data = nil

      bus.subscribe("foo") do |data|
        received_data = data
      end
      expect(received_data).to be_nil

      bus.publish("foo", {foo: 'bar', baz: [{qu: 'ux'}]})
      expect(received_data).to eql({'foo' => 'bar', 'baz' => [{'qu' => 'ux'}]})
    end

    it 'should respond to requests' do
      received_data = nil
      bus.request('hey guys') do |data|
        received_data = data
      end
      expect(received_data).to be_nil

      bus.respond_to_request('hey guys', 'foo')
      expect(received_data).to eql('foo')
    end

    it 'should symbolize keys when responding to requests' do
      received_data = nil
      bus.request('hey guys') do |data|
        received_data = data
      end
      expect(received_data).to be_nil

      bus.respond_to_request('hey guys', {foo: 'bar'})
      expect(received_data).to eql({'foo' => 'bar'})
    end

    it 'should allow unsubscribing from requests' do
      request_id = bus.request('hey guys') do |data|
        raise 'do not call'
      end

      bus.unsubscribe(request_id)
      bus.respond_to_request('hey guys', 'foo')
    end

    it 'should allow unsubscribing from subscriptions' do
      subscription_id = bus.subscribe('hiya') do
        raise 'do not call'
      end

      bus.unsubscribe(subscription_id)
      bus.publish('hiya')
    end

    it 'should call subscribers when requesting data' do
      received_data = nil

      bus.subscribe("foo") do |data|
        received_data = data
      end
      expect(received_data).to be_nil

      publish_data = 'bar'
      bus.request("foo", publish_data)
      expect(received_data).to eql(publish_data)
    end

    it 'should kick off recovery' do
      called = false
      bus.recover do
        called = true
      end
      expect(called).to be_false

      bus.do_recovery
      expect(called).to be_true
    end
  end
end