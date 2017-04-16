# Copyright (c) 2009-2011 VMware, Inc.
require "base64"
require "eventmachine"
require "monitor"
require "nats/client"
require "set"
require "thin"
require "yajl"
require "vcap/stats"

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
      [200, { 'Content-Type' => 'application/json', 'Content-Length' => varz.bytesize.to_s }, varz]
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
      [200, { 'Content-Type' => 'application/json', 'Content-Length' => healthz.bytesize.to_s }, healthz]
    rescue => e
      @logger.error "healthz error #{e.inspect} #{e.backtrace.join("\n")}"
      raise e
    end
  end

  # Common component setup for discovery and monitoring
  class Component
    class SafeHash < BasicObject
      def initialize(hash = {})
        @hash = hash
      end

      def class
        SafeHash
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

    class << self
      def varz
        @varz ||= SafeHash.new
      end

      attr_accessor :healthz

      def updated_varz
        @last_varz_update ||= 0

        if Time.now.to_f - @last_varz_update >= 1
          rss_bytes, pcpu = Stats.process_memory_bytes_and_cpu

          # Update varz
          varz.synchronize do
            @last_varz_update = Time.now.to_f

            varz[:uptime] = VCAP.uptime_string(Time.now - varz[:start])
            varz[:cpu] = pcpu.to_f
            varz[:cpu_load_avg] = Stats.cpu_load_average

            varz[:mem_bytes] = rss_bytes.to_i
            varz[:mem_used_bytes] = Stats.memory_used_bytes
            varz[:mem_free_bytes] = Stats.memory_free_bytes

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
        disallow_exposing_of_config!(opts)

        uuid = VCAP.secure_uuid
        type = opts[:type]
        index = opts[:index]
        job_name = opts[:job_name]
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
        @discover[:job_name] = job_name if job_name

        # Varz is customizable
        varz.synchronize do
          varz.merge!(@discover.dup)
          varz[:num_cores] = VCAP.num_cores
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

      private

      def disallow_exposing_of_config!(opts)
        raise ArgumentError.new("Exposing the config is a security concern, and disallowed.") if opts.has_key?(:config)
      end
    end
  end
end
