# Copyright (c) 2009-2012 VMware, Inc.
require 'spec_helper'
require 'webmock/rspec'

module VCAP::Services::Api
  class ServiceGatewayClient
    public :perform_request
  end
end
describe VCAP::Services::Api::ServiceGatewayClient do
  describe '#perform_request' do
    before :all do
      @url = "http://localhost"
      @https_url = "https://localhost"
      @token = "mytoken"
      @timeout = 10
    end

    it "should use async http client when EM is running" do
      client = VCAP::Services::Api::ServiceGatewayClient.new(@url, @token, @timeout)
      EM.should_receive(:reactor_running?).and_return true

      path = "/path1"
      message = "data"

      http_method = :get

      VCAP::Services::Api::AsyncHttpRequest.should_receive(:request).with(anything, @token, http_method, @timeout, anything).and_return [200, message]

      result = client.perform_request(http_method, path)
      result.should == message
    end

    it "should use net/http client when EM is not running" do
      htturl = "https://localhost"
      client = VCAP::Services::Api::ServiceGatewayClient.new(@url, @token, @timeout)
      EM.should_receive(:reactor_running?).and_return nil

      path = "/path1"
      resp = mock("resq")
      message = "data"
      resp.should_receive(:body).and_return(message)
      resp.should_receive(:code).and_return 200

      http_method = :get

      mock_http = mock("http")
      Net::HTTP.should_receive(:new).with("localhost", 80).and_return mock_http
      mock_http.should_receive(:start).and_yield mock_http
      mock_http.should_receive(:request).and_return resp

      result = client.perform_request(http_method, path)
      result.should == message
    end
    
  it "should use net/https client when EM is not running and https url is provided" do
    client = VCAP::Services::Api::ServiceGatewayClient.new(@https_url, @token, @timeout)
    EM.should_receive(:reactor_running?).and_return nil

    path = "/path1"
    resp = mock("resq")
    message = "data"
    resp.should_receive(:body).and_return(message)
    resp.should_receive(:code).and_return 200

    http_method = :get

    mock_http = mock("http")
    Net::HTTP.should_receive(:new).with("localhost", 443).and_return mock_http
    mock_http.should_receive(:start).and_yield mock_http
    mock_http.should_receive(:use_ssl=).with(true)
    mock_http.should_receive(:request).and_return resp

    result = client.perform_request(http_method, path)
    result.should == message
  end


    it "should should raise error with none 200 response" do
      client = VCAP::Services::Api::ServiceGatewayClient.new(@url, @token, @timeout)
      EM.should_receive(:reactor_running?).any_number_of_times.and_return nil

      path = "/path1"
      resp = mock("resq")
      resp.should_receive(:body).and_return(
        {:code => 40400, :description=> "not found"}.to_json,
        {:code => 50300, :description=> "internal"}.to_json,
        {:code => 50100, :description=> "not done yet"}.to_json,
        {:bad_response => "foo"}.to_json,
      )
      resp.should_receive(:code).and_return(404, 503, 500, 500)
      resp.should_receive(:start).any_number_of_times.and_return resp

      http_method = :get

      Net::HTTP.should_receive(:new).with("localhost", 80).any_number_of_times.and_return resp

      expect {
        client.perform_request(http_method, path)
      }.to raise_error(VCAP::Services::Api::ServiceGatewayClient::NotFoundResponse)
      expect {
        client.perform_request(http_method, path)
      }.to raise_error(VCAP::Services::Api::ServiceGatewayClient::GatewayInternalResponse)
      expect {
        client.perform_request(http_method, path)
      }.to raise_error(VCAP::Services::Api::ServiceGatewayClient::ErrorResponse, /not done yet/)
      expect {
        client.perform_request(http_method, path)
      }.to raise_error(VCAP::Services::Api::ServiceGatewayClient::UnexpectedResponse)
    end
  end

  describe '#unprovision' do
    let(:gateway_url) { "http://gateway.example.com" }
    let(:token) { "mytoken" }
    let(:timeout) { 10 }
    let(:service_id) { 'service-instance-8272' }
    let(:service_url) { "#{gateway_url}/gateway/v1/configurations/#{service_id}" }
    let(:gateway_response_body) do
      {
        "description" => '',
        "code" => 999,
      }.to_json
    end

    subject(:client) do
      VCAP::Services::Api::ServiceGatewayClient.new(gateway_url, token, timeout)
    end

    context 'when the getway returns 422' do
      let(:status){ 422 }

      it 'should raise an GatewayExternalError' do
        stub_request(:delete, service_url).to_return(status:status, body: gateway_response_body)
        expect do
          client.unprovision({service_id: service_id})
        end.to raise_error(described_class::GatewayExternalError)
      end
    end

    context 'when the gateway returns 404' do
      let(:status){ 404 }

      it 'should raise an NotFoundResponse' do
        stub_request(:delete, service_url).to_return(status: status, body: gateway_response_body)
        expect do
          client.unprovision({service_id: service_id})
        end.to raise_error(described_class::NotFoundResponse)
      end
    end
  end
end
