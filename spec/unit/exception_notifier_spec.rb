require "spec_helper"
require "cf/exception_notifier"
describe Cf::ExceptionNotifier do
  let(:valid_config) {
    {
        :api_key => "key",
        :api_host => "host",
        :environment => "env",
        :revision => "ABC123"
    }
  }

  before do
    Squash::Ruby.stub!(:configure)
    Squash::Ruby.stub!(:notify)
    described_class.stub!(:puts)
    described_class.reset
  end

  describe ".setup" do
    it "should configure squash when configuration is provided" do
      Squash::Ruby.should_receive(:configure).with(valid_config)
      described_class.setup(valid_config)
    end

    it "should do nothing if no configuration is provided" do
      Squash::Ruby.should_not_receive(:configure)
      described_class.setup(nil)
      described_class.setup({})
      described_class.setup(:api_host => "host")
      described_class.setup(:environment => "host")
      described_class.setup(:revision => "ABC123")
      described_class.setup(:api_key => "key")
    end
  end

  describe ".notify" do
    it "should pass the exception on to the Squash server" do
      described_class.setup(valid_config)
      ex = StandardError.new("err!")
      Squash::Ruby.should_receive(:notify).with(ex, {:keys => "whered i leave them?"})
      described_class.notify(ex, {:keys => "whered i leave them?"})
    end

    it "should do nothing if not configured" do
      Squash::Ruby.should_not_receive(:notify)
      described_class.notify(Exception.new)
    end
  end
end
