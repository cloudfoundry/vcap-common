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
      expect(uptime_in_seconds).to eq(1 * 24 * 3600 + 1 * 3600 + 1 * 60 + 1)
    end

    it "raises an exception if the string is in the wrong format" do
      expect {
        VCAP.uptime_string_to_seconds("hello")
      }.to raise_error(ArgumentError)
    end

  end

  describe '.num_cores' do

    describe 'linux' do
      it 'returns number of cores' do
        stub_const('RUBY_PLATFORM', 'x86_64 linux')
        subject.should_receive(:'`').with('cat /proc/cpuinfo | grep processor | wc -l').and_return('4')
        expect(VCAP.num_cores).to eq 4
      end
    end

    describe 'darwin' do

      context 'when hwprefs is available' do
        it 'returns number of cores' do
          stub_const('RUBY_PLATFORM', 'x86_64 darwin')
          subject.should_receive(:'`').with('hwprefs cpu_count').and_return('4')
          expect(VCAP.num_cores).to eq 4
        end
      end

      context 'when hwprefs is not available' do
        it 'returns default number of cores' do
          stub_const('RUBY_PLATFORM', 'x86_64 darwin')
          subject.should_receive(:'`').with('hwprefs cpu_count').and_raise(Errno::ENOENT)
          expect(VCAP.num_cores).to eq 1
        end
      end

    end

    describe 'freebsd' do
      it 'returns number of cores' do
        stub_const('RUBY_PLATFORM', 'x86_64 freebsd')
        subject.should_receive(:'`').with('sysctl hw.ncpu').and_return('4')
        expect(VCAP.num_cores).to eq 4
      end
    end

    describe 'netbsd' do
      it 'returns number of cores' do
        stub_const('RUBY_PLATFORM', 'x86_64 netbsd')
        subject.should_receive(:'`').with('sysctl hw.ncpu').and_return('4')
        expect(VCAP.num_cores).to eq 4
      end
    end

    describe 'windows' do

      before do
        stub_const('RUBY_PLATFORM', 'foo')
        stub_const('VCAP::WINDOWS', true)
      end

      context 'when NUMBER_OF_PROCESSORS is set' do
        it 'returns number of cores' do
          ENV.stub(:[]).with('NUMBER_OF_PROCESSORS').and_return('7')

          expect(VCAP.num_cores).to eq 7
        end
      end

      context 'when NUMBER_OF_PROCESSORS is not set' do
        it 'returns default number of cores' do
          ENV.stub(:[]).with('NUMBER_OF_PROCESSORS').and_return(nil)
          expect(VCAP.num_cores).to eq(1)
        end
      end
    end

    describe 'unknown' do
      it 'returns default number of cores' do
        stub_const('RUBY_PLATFORM', 'foo')
        stub_const('VCAP::WINDOWS', false)
        expect(VCAP.num_cores).to eq(1)
      end
    end

  end

  describe '.process_running?' do
    before do
      allow_message_expectations_on_nil
    end

    describe 'invalid pid' do
      it 'should return false with negative pid' do
        expect(VCAP.process_running?(-5)).to be_false
      end
      it 'should return false with nil pid' do
        expect(VCAP.process_running?(nil)).to be_false
      end
    end

    describe 'unix' do
      before do
        stub_const('VCAP::WINDOWS', false)
        $?.stub(:'==').with(0) { true }
      end

      it 'With a running process' do
        subject.should_receive(:'`').with('ps -o rss= -p 12').and_return('some output')
        expect(VCAP.process_running?(12)).to be_true
      end

      it 'Without a running process' do
        subject.should_receive(:'`').with('ps -o rss= -p 12').and_return('')
        expect(VCAP.process_running?(12)).to be_false
      end
    end


    describe 'windows' do
      before do
        stub_const('VCAP::WINDOWS', true)
        $?.stub(:'==').with(0) { true }
      end

      it 'With a running process' do
        subject.should_receive(:'`').with('tasklist /nh /fo csv /fi "pid eq 12"').and_return('some output')
        expect(VCAP.process_running?(12)).to be_true
      end

      it 'Without a running process' do
        subject.should_receive(:'`').with('tasklist /nh /fo csv /fi "pid eq 12"').and_return('')
        expect(VCAP.process_running?(12)).to be_false
      end
    end
  end
end