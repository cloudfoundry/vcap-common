# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"
require "tempfile"
require "timeout"
require "sinatra"

require "services/api/clients/sds_client"

describe VCAP::Services::Api::SDSClient do
  describe "#import_from_data" do
    it "issues a PUT to serialization data server" do
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
      MockServer.last_request.forms["data_file"].should_not be_nil
      MockServer.last_request.forms["data_file"][:tempfile].read.should == "bar\n"
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

  enable :method_override

  put "/*" do
    record_signature(request)

    [self.class.stubbed_status, self.class.stubbed_body]
  end
end
