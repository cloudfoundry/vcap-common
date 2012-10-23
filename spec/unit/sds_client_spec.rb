# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"
require "tempfile"
require "timeout"
require "sinatra"

require "services/api/clients/sds_client"

describe VCAP::Services::Api::SDSClient do
  describe "#import_from_data" do
    it "issues a PUT to serialization data server" do
      # webmock would be great, but unfortunately it's a monkey-patch, and we
      # are (even more unfortunately) doing yet another monkey-patch on
      # em-http-request, so their monkey patch can't catch calls to our monkey
      # patch. So we have to roll out this hard-core real servers all over the
      # place. Yuck
      MockServer.stubbed_status = 200
      MockServer.stubbed_body = "{\"url\": \"http://example.com/foo\"}"
      port = VCAP::grab_ephemeral_port
      server = Thin::Server.new("localhost", port, MockServer)
      server.silent = true
      t = Thread.new { server.start }

      f = Tempfile.new("foo")
      f.write("bar\n")
      f.close

      client = VCAP::Services::Api::SDSClient.new(
        "http://localhost:#{port}",
        "secret",
      )
      EM.error_handler do |e|
        raise e
      end
      Timeout.timeout(0.5) do
        sleep 0.02 until server.running?
      end
      server.should be_running

      EM.next_tick do
        fiber = Fiber.new do
          client.import_from_data(
            :service => "redis",
            :service_id => "deadbeef",
            :msg => f.path,
          )
          EM.stop
        end
        fiber.resume
      end
      Timeout.timeout(0.5) do
        EM.reactor_thread.join
      end
      f.unlink
      MockServer.last_request.forms["data_file"].should_not be_nil
      MockServer.last_request.forms["data_file"][:tempfile].read.should == "bar\n"
      MockServer.last_request.headers["HTTP_X_VCAP_SDS_UPLOAD_TOKEN"].should == "secret"
    end

    it "issues a PUT to serialization data server (outside of reactor thread)" do
      MockServer.stubbed_status = 200
      MockServer.stubbed_body = "{\"url\": \"http://example.com/foo\"}"
      port = VCAP::grab_ephemeral_port
      server = Thin::Server.new("localhost", port, MockServer)
      server.silent = true
      Thread.new { server.start }

      f = Tempfile.new("foo")
      f.write("bar\n")
      f.close

      client = VCAP::Services::Api::SDSClient.new(
        "http://localhost:#{port}",
        "secret",
        2,
      )
      EM.error_handler do |e|
        raise e
      end
      Timeout.timeout(0.5) do
        sleep 0.02 until server.running?
      end
      server.should be_running

      client.import_from_data(
        :service => "redis",
        :service_id => "deadbeef",
        :msg => f.path,
      )
      server.stop
      Timeout.timeout(0.5) do
        EM.reactor_thread.join
      end
      f.unlink
      MockServer.last_request.forms["data_file"].should_not be_nil
      MockServer.last_request.forms["data_file"][:tempfile].read.should == "bar\n"
      MockServer.last_request.headers["HTTP_X_VCAP_SDS_UPLOAD_TOKEN"].should == "secret"
    end

    it "issues a PUT to serialization data server (without EM)" do
      MockServer.stubbed_status = 200
      MockServer.stubbed_body = "{\"url\": \"http://example.com/foo\"}"
      server = nil
      Thread.abort_on_exception = true
      port = VCAP::grab_ephemeral_port
      t = Thread.new do
        Rack::Handler::WEBrick.run(MockServer,
                                   :Port => port,
                                   :Host => "localhost",
                                   # shut up webrick
                                   :Logger => WEBrick::Log.new(nil, WEBrick::Log::WARN),
                                   :AccessLog => [],
                                  ) do |s|
          server = s
        end
      end

      f = Tempfile.new("foo")
      f.write("bar\n")
      f.close

      client = VCAP::Services::Api::SDSClient.new(
        "http://localhost:#{port}",
        "secret",
        2,
      )
      Timeout.timeout(0.5) do
        sleep 0.02 until server && server.status == :Running
      end
      server.status.should == :Running

      client.import_from_data(
        :service => "redis",
        :service_id => "deadbeef",
        :msg => f.path,
      )
      # server#stop woul also do, but it takes 2 seconds...
      server.shutdown
      Timeout.timeout(0.5) do
        t.kill
        t.join
      end
      f.unlink
      MockServer.last_request.forms["data_file"].should_not be_nil
      MockServer.last_request.forms["data_file"][:tempfile].read.should == "bar\n"
      MockServer.last_request.headers["HTTP_X_VCAP_SDS_UPLOAD_TOKEN"].should == "secret"
    end
  end
end

class MockServer < Sinatra::Base
  RequestSignature = Struct.new(
    :path,
    :headers,
    :forms,
  )
  class << self
    @stubbed_status = 204
    @stubbed_body = ""
    attr_accessor :last_request, :stubbed_status, :stubbed_body
  end

  private
  def record_signature(request)
    r = RequestSignature.new
    r.path = request.path
    r.headers = request.env.select { |k,_| k.start_with?("HTTP_") }
    r.forms = request.POST.dup
    self.class.last_request = r
  end

  # FIXME: drop this when we switch to true PUT
  enable :method_override

  put "/*" do
    record_signature(request)

    [self.class.stubbed_status, self.class.stubbed_body]
  end
end
