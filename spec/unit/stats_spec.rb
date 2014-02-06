require "spec_helper"
require "vcap/stats"
require "ostruct"

describe VCAP::Stats do
  describe "on Unix" do
    before do
      stub_const('VCAP::WINDOWS', false)
      Process.stub(pid: 9999)
    end

    it "should retrieve process memory and cpu" do
      VCAP::Stats.should_receive(:'`').with("ps -o rss=,pcpu= -p 9999").and_return("55792 12")

      mem_bytes, cpu = VCAP::Stats.process_memory_bytes_and_cpu
      expect(mem_bytes).to eq(55792 * 1024)
      expect(cpu).to eq(12)
    end

    it "should retrieve cpu_load" do
      Vmstat.stub_chain(:load_average, :one_minute).and_return(3)

      expect(VCAP::Stats.cpu_load_average).to eq(3)
    end

    it "should retrieve physical memory total and available" do
      Vmstat.should_receive(:memory).twice.and_return do
        o = OpenStruct.new
        o.active_bytes = 3
        o.wired_bytes = 5
        o.inactive_bytes = 7
        o.free_bytes = 11
        o
      end

      expect(VCAP::Stats.memory_used_bytes).to eq(8)
      expect(VCAP::Stats.memory_free_bytes).to eq(18)
    end
  end

  describe "on Windows" do
    before do
      stub_const("VCAP::WINDOWS", true)
      Process.stub(pid: 9999)
    end

    let(:system_memory_list) {
      <<MEM_LIST
Total Physical Memory:     8,191 MB
Available Physical Memory: 5,903 MB
MEM_LIST
    }

    let(:task_list) {
      'ruby.exe                       416 Console                    1     55,792 K'
    }

    let(:process_time) {
      <<TIME

"(PDH-CSV 4.0)","\\MACHINE\Process(rubymine)\% processor time"
"09/19/2013 15:41:35.540","12.000000"

The command completed successfully.
TIME
    }

    let(:process_list) {
      <<LIST

"(PDH-CSV 4.0)","\\MACHINE\Process(rubymine)\ID Process"
"09/19/2013 15:38:46.438","9999.000000"

The command completed successfully.
LIST
    }

    it 'should retrieve process memory and cpu' do
      VCAP::Stats.should_receive(:'`').with('tasklist /nh /fi "pid eq 9999"').and_return(task_list)

      VCAP::Stats.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\ID Process"').and_return(process_list)
      VCAP::Stats.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\% processor time"').and_return(process_time)

      mem_bytes, cpu = VCAP::Stats.process_memory_bytes_and_cpu
      expect(mem_bytes).to eq(55792 * 1024)
      expect(cpu).to eq(12)
    end

    it 'should retrieve cpu_load' do
      VCAP::Stats.should_receive(:'`').with('powershell -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned "Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Foreach {$_.Average}"').and_return(24)

      expect(VCAP::Stats.cpu_load_average).to eq 24
    end

    it 'should retrieve physical memory total and available' do
      VCAP::Stats.should_receive(:'`').with('systeminfo | findstr "\\<Physical Memory>\\"').and_return(system_memory_list)

      mem = VCAP::Stats.memory_used_bytes
      expect(mem).to eq 8588886016 - 6189744128
    end
  end
end
