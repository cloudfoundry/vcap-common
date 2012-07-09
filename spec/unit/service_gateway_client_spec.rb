# Copyright (c) 2009-2012 VMware, Inc.
require 'spec_helper'

module VCAP::Services::Api
  class ServiceGatewayClient
    public :perform_request
  end
end
describe VCAP::Services::Api::ServiceGatewayClient do
  describe '#perform_request' do
    before :all do
      @url = "http://localhost"
      @token = "mytoken"
      @timeout = 10
    end

    it "should use async http client when EM is running" do
      client = VCAP::Services::Api::ServiceGatewayClient.new(@url, @token, @timeout)
      EM.should_receive(:reactor_running?).and_return true

      path = "/path1"
      resp = mock("resq")
      message = "data"
      resp.should_receive(:response).and_return(message)
      resp.should_receive(:error).and_return []

      resp_header = mock("resq_header")
      resp_header.should_receive(:status).and_return(200)
      resp.should_receive(:response_header).and_return resp_header
      http_method = :get

      VCAP::Services::Api::AsyncHttpRequest.should_receive(:fibered).with(anything, @token, http_method, @timeout, anything).and_return resp

      result = client.perform_request(http_method, path)
      result.should == message
    end

    it "should use net/http client when EM is not running" do
      client = VCAP::Services::Api::ServiceGatewayClient.new(@url, @token, @timeout)
      EM.should_receive(:reactor_running?).and_return nil

      path = "/path1"
      resp = mock("resq")
      message = "data"
      resp.should_receive(:body).and_return(message)
      resp.should_receive(:code).and_return 200
      resp.should_receive(:start).and_return resp

      http_method = :get

      Net::HTTP.should_receive(:new).with("localhost", 80).and_return resp

      result = client.perform_request(http_method, path)
      result.should == message
    end
  end
end
