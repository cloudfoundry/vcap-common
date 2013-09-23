require 'spec_helper'

require 'vcap/win_stats'

describe VCAP::WinStats do
  before do
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

  it 'should retrieve process memory' do
    VCAP::WinStats.should_receive(:'`').with('tasklist /nh /fi "pid eq 9999"').and_return(task_list)

    expect(VCAP::WinStats.process_memory).to eq 55792
  end

  it 'should retrieve process cpu' do
    VCAP::WinStats.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\ID Process"').and_return(process_list)
    VCAP::WinStats.should_receive(:'`').with('typeperf -sc 1 "\\Process(ruby*)\\% processor time"').and_return(process_time)

    expect(VCAP::WinStats.process_cpu).to eq 12
  end

  it 'should retrieve cpu_load' do
    VCAP::WinStats.should_receive(:'`').with('powershell -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned "Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Foreach {$_.Average}"').and_return(24)

    expect(VCAP::WinStats.cpu_load).to eq 24
  end

  it 'should retrieve physical memory total and available' do
    VCAP::WinStats.should_receive(:'`').with('systeminfo | findstr "\\<Physical Memory>\\"').and_return(system_memory_list)

    mem_hash = VCAP::WinStats.memory_used
    expect(mem_hash[:total]).to eq 8588886016
    expect(mem_hash[:available]).to eq 6189744128
  end
end