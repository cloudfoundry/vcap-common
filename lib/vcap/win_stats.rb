require 'vcap/common'

module VCAP
  class WinStats
    class << self
      def memory_used
        mem_ary = system_memory_list.split
        mem = Hash.new
        mem[:total] = (mem_ary[3].gsub(',', '').to_i * 1024) * 1024
        mem[:available] = (mem_ary[8].gsub(',', '').to_i * 1024) * 1024
        mem
      end

      def cpu_load
        avg_load = %x[powershell -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned "Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Foreach {$_.Average}"]
        avg_load.to_i
      end

      def process_memory
        out_ary = memory_list.split
        rss = out_ary[4].delete(',').to_i
      end

      def process_cpu
        pcpu = 0
        process_ary = process_list
        pid = Process.pid
        idx_of_process = -1
        process_line_ary = process_ary.split("\n")
        ary_to_search = process_line_ary[2].split(',')
        ary_to_search.each_with_index { |val, idx|
          pid_s = val.gsub(/"/, '')
          pid_to_i = pid_s.to_i
          if pid == pid_to_i
            idx_of_process = idx
          end
        }
        if idx_of_process >= 0
          cpu_ary = process_time
          cpu_line_ary = cpu_ary.split("\n")
          ary_to_search = cpu_line_ary[2].split(',')
          cpu = ary_to_search[idx_of_process]
          pcpu = cpu.gsub(/"/, '').to_f
        end
        pcpu
      end

      private

      def system_memory_list
        mem_ary = %x[systeminfo | findstr "\\<Physical Memory>\\"]
      end

      def memory_list
        out_ary = %x[tasklist /nh /fi "pid eq #{Process.pid}"]
      end

      def process_time
        cpu_ary = %x[typeperf -sc 1 "\\Process(ruby*)\\% processor time"]
      end

      def process_list
        process_str = %x[typeperf -sc 1 "\\Process(ruby*)\\ID Process"]
      end
    end
  end
end