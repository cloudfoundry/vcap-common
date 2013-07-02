require "cf_message_bus/message_bus_factory"

module CfMessageBus
  describe MessageBusFactory do
    let(:uri) { "nats://localhost:4222" }
    let(:client) { double(:client) }
    subject(:get_bus) { MessageBusFactory.message_bus(uri) }
    before do
      ::NATS.stub(:connect).and_return(client)
    end

    it { should == client }

    it 'should connect to the uri' do
      ::NATS.should_receive(:connect).with(hash_including(uri: uri))
      get_bus
    end

    it 'should setup infinite retry' do
      ::NATS.should_receive(:connect).with(hash_including(max_reconnect_attempts: Float::INFINITY))
      get_bus
    end
  end
end