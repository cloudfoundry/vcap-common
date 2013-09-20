require "spec_helper"

describe VCAP do
  describe ".uptime_string_to_seconds" do
    it "takes a string in dhms format and returns seconds" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("0d:0h:0m:0s")
      expect(uptime_in_seconds).to eq(0)
    end

    it "parses seconds" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("0d:0h:0m:16s")
      expect(uptime_in_seconds).to eq(16)
    end

    it "parses min" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("0d:0h:16m:0s")
      expect(uptime_in_seconds).to eq(16 * 60)
    end

    it "parses hours" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("0d:16h:0m:0s")
      expect(uptime_in_seconds).to eq(16* 3600)
    end

    it "parses days" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("16d:0h:0m:0s")
      expect(uptime_in_seconds).to eq(16 * 24 * 3600)
    end

    it "parses everything" do
      uptime_in_seconds = VCAP.uptime_string_to_seconds("1d:1h:1m:1s")
      expect(uptime_in_seconds).to eq( 1 * 24 * 3600 + 1 * 3600 + 1 * 60 + 1)
    end

    it "raises an exception if the string is in the wrong format" do
      expect {
        VCAP.uptime_string_to_seconds("hello")
      }.to raise_error(ArgumentError)
    end

  end

  describe ".num_cores", windows_only:true do
    it "returns number of cores" do
      expect(VCAP.num_cores).to eq(ENV['NUMBER_OF_PROCESSORS'].to_i)
    end
  end

  describe ".process_running?", windows_only:true do
    before do
      allow_message_expectations_on_nil
    end

    describe "windows" do
      before do
        stub_const('VCAP::WINDOWS', true)
        $?.stub(:'==').with(0) { true }
      end

      it "With a running process" do
        subject.should_receive(:'`').with('tasklist /nh /fo csv /fi "pid eq 12"').and_return('some output')
        expect(VCAP.process_running?(12)).to be_true
      end

      it "Without a running process" do
        subject.should_receive(:'`').with('tasklist /nh /fo csv /fi "pid eq 12"').and_return('')
        expect(VCAP.process_running?(12)).to be_false
      end
    end
  end
end