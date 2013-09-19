# Copyright (c) 2009-2011 VMware, Inc.
require "base64"
require "eventmachine"
require "monitor"
require "nats/client"
require "set"
require "thin"
require "yajl"
require "vmstat"

module VCAP

  RACK_JSON_HDR = { 'Content-Type' => 'application/json' }
  RACK_TEXT_HDR = { 'Content-Type' => 'text/plaintext' }

  class Varz
    def initialize(logger)
      @logger = logger
    end

    def call(env)
      @logger.debug "varz access"
      varz = Yajl::Encoder.encode(Component.updated_varz, :pretty => true, :terminator => "\n")
      [200, { 'Content-Type' => 'application/json', 'Content-Length' => varz.length.to_s }, varz]
    rescue => e
      @logger.error "varz error #{e.inspect} #{e.backtrace.join("\n")}"
      raise e
    end
  end

  class Healthz
    def initialize(logger)
      @logger = logger
    end

    def call(env)
      @logger.debug "healthz access"
      healthz = Component.updated_healthz
      [200, { 'Content-Type' => 'application/json', 'Content-Length' => healthz.length.to_s }, healthz]
    rescue => e
      @logger.error "healthz error #{e.inspect} #{e.backtrace.join("\n")}"
      raise e
    end
  end

  # Common component setup for discovery and monitoring
  class Component

    # We will suppress these from normal varz reporting by default.
    CONFIG_SUPPRESS = Set.new([:mbus, :service_mbus, :keys, :database_environment, :password, :pass, :token])

    class << self
      class SafeHash < BasicObject
        def initialize(hash = {})
          @hash = hash
        end

        def threadsafe!
          @monitor = ::Monitor.new
        end

        def synchronize
          if @monitor
            @monitor.synchronize do
              begin
                @thread = ::Thread.current
                yield
              ensure
                @thread = nil
              end
            end
          else
            yield
          end
        end

        def method_missing(sym, *args, &blk)
          if @monitor && @thread != ::Thread.current
            ::Kernel.raise "Lock required"
          end

          @hash.__send__(sym, *args, &blk)
        end
      end

      def varz
        @varz ||= SafeHash.new
      end

      attr_accessor :healthz

      def updated_varz
        @last_varz_update ||= 0

        if Time.now.to_f - @last_varz_update >= 1
          # Grab current cpu and memory usage
          if WINDOWS
            # memory
            rss = windows_memory
            pcpu = windows_cpu
          else
            rss, pcpu = `ps -o rss=,pcpu= -p #{Process.pid}`.split
          end

          # Update varz
          varz.synchronize do
            @last_varz_update = Time.now.to_f

            varz[:uptime] = VCAP.uptime_string(Time.now - varz[:start])
            varz[:mem] = rss.to_i
            varz[:cpu] = pcpu.to_f

            memory = Vmstat.memory
            varz[:mem_used_bytes] = memory.active_bytes + memory.wired_bytes
            varz[:mem_free_bytes] = memory.inactive_bytes + memory.free_bytes

            varz[:cpu_load_avg] = Vmstat.load_average.one_minute

            # Return duplicate while holding lock
            return varz.dup
          end
        else
          # Return duplicate while holding lock
          varz.synchronize do
            return varz.dup
          end
        end
      end

      def updated_healthz
        @last_healthz_update ||= 0

        if Time.now.to_f - @last_healthz_update >= 1
          @last_healthz_update = Time.now.to_f
        end

        healthz.dup
      end

      def start_http_server(host, port, auth, logger)
        http_server = Thin::Server.new(host, port, :signals => false) do
          Thin::Logging.silent = true
          use Rack::Auth::Basic do |username, password|
            [username, password] == auth
          end
          map '/healthz' do
            run Healthz.new(logger)
          end
          map '/varz' do
            run Varz.new(logger)
          end
        end
        http_server.start!
      end

      def uuid
        @discover[:uuid]
      end

      # Announces the availability of this component to NATS.
      # Returns the published configuration of the component,
      # including the ephemeral port and credentials.
      def register(opts)
        uuid = VCAP.secure_uuid
        type = opts[:type]
        index = opts[:index]
        uuid = "#{index}-#{uuid}" if index
        host = opts[:host] || VCAP.local_ip
        port = opts[:port] || VCAP.grab_ephemeral_port
        nats = opts[:nats] || NATS
        auth = [opts[:user] || VCAP.secure_uuid, opts[:password] || VCAP.secure_uuid]
        logger = opts[:logger] || Logger.new(nil)
        log_counter = opts[:log_counter]

        # Discover message limited
        @discover = {
          :type => type,
          :index => index,
          :uuid => uuid,
          :host => "#{host}:#{port}",
          :credentials => auth,
          :start => Time.now
        }

        # Varz is customizable
        varz.synchronize do
          varz.merge!(@discover.dup)
          varz[:num_cores] = VCAP.num_cores
          varz[:config] = sanitize_config(opts[:config]) if opts[:config]
          varz[:log_counts] = log_counter if log_counter
        end

        @healthz = "ok\n".freeze

        # Next steps require EM
        raise "EventMachine reactor needs to be running" if !EventMachine.reactor_running?

        # Startup the http endpoint for /varz and /healthz
        start_http_server(host, port, auth, logger)

        # Listen for discovery requests
        nats.subscribe('vcap.component.discover') do |msg, reply|
          update_discover_uptime
          nats.publish(reply, @discover.to_json)
        end

        # Also announce ourselves on startup..
        nats.publish('vcap.component.announce', @discover.to_json)

        @discover
      end

      def update_discover_uptime
        @discover[:uptime] = VCAP.uptime_string(Time.now - @discover[:start])
      end

      def clear_level(h)
        h.each do |k, v|
          if CONFIG_SUPPRESS.include?(k.to_sym)
            h.delete(k)
          else
            clear_level(h[k]) if v.instance_of? Hash
          end
        end
      end

      def sanitize_config(config)
        # Can't Marshal/Deep Copy logger instances that services use
        if config[:logger]
          config = config.dup
          config.delete(:logger)
        end
        # Deep copy
        config = Marshal.load(Marshal.dump(config))
        clear_level(config)
        config
      end

      private

      def windows_memory
        out_ary = memory_list.split
        rss = out_ary[4].delete(',').to_i
        rss
      end

      def memory_list
        out_ary = %x[tasklist /nh /fi "pid eq #{Process.pid}"]
        out_ary
      end

      def windows_cpu
        pcpu = 0
        process_ary = process_list
        pid = Process.pid
        idx_of_process = -1
        process_line_ary = process_ary.split("\n")
        ary_to_search = process_line_ary[2].split(",")
        ary_to_search.each_with_index { |val, idx|
          pid_s = val.gsub(/"/, '')
          pid_to_i = pid_s.to_i
          if (pid == pid_to_i)
            idx_of_process = idx
          end
        }
        if idx_of_process >= 0
          cpu_ary = process_time
          cpu_line_ary = cpu_ary.split("\n")
          ary_to_search = cpu_line_ary[2].split(",")
          cpu = ary_to_search[idx_of_process]
          pcpu = cpu.gsub(/"/, '').to_f
        end
        pcpu
      end

      def process_list
        process_str = %x[typeperf -sc 1 "\\Process(ruby*)\\ID Process"]
        process_str
      end

      def process_time
        cpu_ary = %x[typeperf -sc 1 "\\Process(ruby*)\\% processor time"]
        cpu_ary
      end
    end
  end
end
