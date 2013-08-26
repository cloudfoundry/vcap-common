require 'cf_message_bus'
require 'support/mock_nats'
require 'nats/client'

describe CfMessageBus do
  before do
    NATS.stub(:connect).and_return(CfMessageBus::MockNATS.new)
  end

  it 'should return a non-mocked message bus by default' do
    expect(CfMessageBus.make_message_bus({})).to be_a(CfMessageBus::MessageBus)
  end

  describe 'when mocked' do
    before { CfMessageBus.mock! }

    it 'should return a mock message bus when mocked' do
      expect(CfMessageBus.make_message_bus({})).to be_a(CfMessageBus::MockMessageBus)
    end

    it 'should allow retrival of the mocked message bus' do
      created_bus = CfMessageBus.make_message_bus({})
      expect(CfMessageBus.mocked_message_bus).to eq(created_bus)
    end

    it 'should return a non-mocked message bus when un mocked' do
      CfMessageBus.unmock!
      expect(CfMessageBus.make_message_bus({})).to be_a(CfMessageBus::MessageBus)
    end
  end
end