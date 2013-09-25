# Copyright (c) 2009-2012 VMware, Inc.
require 'spec_helper'
require 'webmock/rspec'

module VCAP::Services::Api
  describe ServiceGatewayClient do
    let(:gateway_url) { 'http://gateway.example.com' }
    let(:token) { 'mytoken' }
    let(:timeout) { 10 }
    let(:request_id) { SecureRandom.uuid }

    let(:http_client) { double(:http_client) }

    subject(:client) do
      ServiceGatewayClient.new(gateway_url, token, timeout, request_id)
    end

    before do
      ServiceGatewayClient::HttpClient.stub(:new).and_return(http_client)
    end

    describe '#initialize' do
      it 'properly instantiates the http client' do
        ServiceGatewayClient::HttpClient.should_receive(:new).
          with(gateway_url, token, timeout, request_id).
          and_return(http_client)

        ServiceGatewayClient.new(gateway_url, token, timeout, request_id)
      end
    end

    describe '#provision' do
      it 'sends a POST request to the correct endpoint' do
        http_client.should_receive(:perform_request).
          with(:post, '/gateway/v1/configurations', an_instance_of(GatewayProvisionRequest)).
          and_return({
            service_id: '456',
            configuration: {setting: true},
            credentials: {user: 'admin', pass: 'secret'}
          }.to_json)

        response = client.provision(unique_id: '123', name: 'Example Service')
        expect(response.service_id).to be == '456'
        expect(response.configuration).to be == {'setting' => true}
        expect(response.credentials).to be == {'user' => 'admin', 'pass' => 'secret'}
      end
    end

    describe '#unprovision' do
      it 'sends a DELETE request to the correct endpoint' do
        http_client.should_receive(:perform_request).
          with(:delete, '/gateway/v1/configurations/service-instance-8272')

        client.unprovision(service_id: 'service-instance-8272')
      end
    end

    describe '#bind' do
      it 'sends a POST request to the correct endpoint' do
        service_id = '123'
        http_client.should_receive(:perform_request).
          with(:post, "/gateway/v1/configurations/#{service_id}/handles", an_instance_of(GatewayBindRequest)).
          and_return({
            service_id: service_id,
            configuration: {setting: true},
            credentials: {user: 'admin', pass: 'secret'},
            syslog_drain_url: "syslog://example.com"
          }.to_json)

        response = client.bind(service_id: service_id)
        expect(response.service_id).to be == service_id
        expect(response.configuration).to be == {'setting' => true}
        expect(response.credentials).to be == {'user' => 'admin', 'pass' => 'secret'}
        expect(response.syslog_drain_url).to be == "syslog://example.com"
      end
    end

    describe '#unbind' do
      it 'sends a DELETE request to the correct endpoint' do
        service_id = '123'
        handle_id = '456'
        http_client.should_receive(:perform_request).
          with(:delete, "/gateway/v1/configurations/#{service_id}/handles/#{handle_id}", an_instance_of(GatewayUnbindRequest))

        client.unbind(service_id: service_id, handle_id: handle_id, binding_options: {})
      end
    end
  end

  describe ServiceGatewayClient::HttpClient do
    describe '#perform_request' do
      let(:url) { 'http://localhost' }
      let(:token) { 'mytoken' }
      let(:timeout) { 10 }
      let(:request_id) { "request-id-beef" }

      let(:http_client) { described_class.new(url, token, timeout, request_id) }

      it 'makes GET requests' do
        request = stub_request(:get, 'http://localhost/path1').
          with(headers: {
            "X-VCAP-Request-ID" => request_id,
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
          }).
          to_return(status: 200, body: 'data')

        result = http_client.perform_request(:get, '/path1')
        result.should == 'data'

        request.should have_been_made
      end
      
      describe '#perform_request (https)' do
        let(:url) { 'https://localhost' }

        it 'makes https GET requests' do
          request = stub_request(:get, 'https://localhost/path1').
          with(headers: {
            "X-VCAP-Request-ID" => request_id,
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token
          }).
          to_return(status: 200, body: 'data')

          result = http_client.perform_request(:get, '/path1')
          result.should == 'data'

          request.should have_been_made
        end
      end

      context "when request_id is nil" do
        it "makes POST requests without the X-VCAP-Request-ID header" do
          client = described_class.new(url, token, timeout, nil)

          request = stub_request(:post, 'http://localhost/path1').
            with(headers: {
              VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
            }).
            to_return(status: 200, body: 'data')

          result = client.perform_request(:post, '/path1')
          result.should == 'data'

          request.should have_been_made
        end
      end

      it 'makes POST requests' do
        request = stub_request(:post, 'http://localhost/path1').
          with(headers: {
            "X-VCAP-Request-ID" => "request-id-beef",
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
          }).
          to_return(status: 200, body: 'data')

        result = http_client.perform_request(:post, '/path1')
        result.should == 'data'

        request.should have_been_made
      end

      it 'makes PUT requests' do
        request = stub_request(:put, 'http://localhost/path1').
          with(headers: {
            "X-VCAP-Request-ID" => "request-id-beef",
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
          }).
          to_return(status: 200, body: 'data')

        result = http_client.perform_request(:put, '/path1')
        result.should == 'data'

        request.should have_been_made
      end

      it 'makes DELETE requests' do
        request = stub_request(:delete, 'http://localhost/path1').
          with(headers: {
            "X-VCAP-Request-ID" => "request-id-beef",
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
          }).
          to_return(status: 200, body: 'data')

        result = http_client.perform_request(:delete, '/path1')
        result.should == 'data'

        request.should have_been_made
      end

      def self.it_raises_an_exception_when(opts)
        expected_exception = opts.fetch(:exception)
        response_status_code = opts.fetch(:response_status)

        let(:error_code) { rand(5000) }
        let(:error_description) { SecureRandom.uuid }
        let(:backtrace) { ["/dev/null:20:in `catch'", "/dev/null:69:in `start'", "/dev/null:12:in `<main>'"]}
        let(:types) { ["ServiceError", "StandardError", "Exception"]}

        context "when the response status is #{response_status_code}" do
          before do
            stub_request(:any, /.*/).to_return(
              status: response_status_code,
              body: {
                code: error_code,
                description: error_description,
                error: {
                  backtrace: backtrace,
                  types: types
                }
              }.to_json
            )
          end

          it "raises a #{expected_exception.name} for get requests" do
            expect {
              http_client.perform_request(:get, url)
            }.to raise_error(expected_exception) { |exception|
              exception.status.should == response_status_code
              exception.error.code.should == error_code
              exception.error.description.should == error_description
              exception.error.error.fetch('backtrace').should == backtrace
              exception.error.error.fetch('types').should == types
              error_hash = exception.to_h
              error_hash.fetch('error').fetch('description').should == error_description
              error_hash.fetch('error').fetch('code').should == error_code
              error_hash.fetch('error').fetch('backtrace').should_not be_empty
              error_hash.fetch('error').fetch('types').should include(
                "VCAP::Services::Api::ServiceGatewayClient::ErrorResponse"
              )
              error_hash.fetch('error').fetch('error').should == {
                'backtrace' => backtrace,
                'types' => types
              }
            }
          end

          it "raises a #{expected_exception.name} for post requests" do
            expect {
              http_client.perform_request(:post, url)
            }.to raise_error(expected_exception) { |exception|
              exception.status.should == response_status_code
              exception.error.code.should == error_code
              exception.error.description.should == error_description
              exception.error.error.fetch('backtrace').should == backtrace
              exception.error.error.fetch('types').should == types
              error_hash = exception.to_h
              error_hash.fetch('error').fetch('description').should == error_description
              error_hash.fetch('error').fetch('code').should == error_code
              error_hash.fetch('error').fetch('backtrace').should_not be_empty
              error_hash.fetch('error').fetch('types').should include(
                "VCAP::Services::Api::ServiceGatewayClient::ErrorResponse"
              )
              error_hash.fetch('error').fetch('error').should == {
                'backtrace' => backtrace,
                'types' => types
              }
            }
          end

          it "raises a #{expected_exception.name} for put requests" do
            expect {
              http_client.perform_request(:put, url)
            }.to raise_error(expected_exception) { |exception|
              exception.status.should == response_status_code
              exception.error.code.should == error_code
              exception.error.description.should == error_description
              exception.error.error.fetch('backtrace').should == backtrace
              exception.error.error.fetch('types').should == types
              error_hash = exception.to_h
              error_hash.fetch('error').fetch('description').should == error_description
              error_hash.fetch('error').fetch('code').should == error_code
              error_hash.fetch('error').fetch('backtrace').should_not be_empty
              error_hash.fetch('error').fetch('types').should include(
                "VCAP::Services::Api::ServiceGatewayClient::ErrorResponse"
              )
              error_hash.fetch('error').fetch('error').should == {
                'backtrace' => backtrace,
                'types' => types
              }
            }
          end

          it "raises a #{expected_exception.name} for delete requests" do
            expect {
              http_client.perform_request(:delete, url)
            }.to raise_error(expected_exception) { |exception|
              exception.status.should == response_status_code
              exception.error.code.should == error_code
              exception.error.description.should == error_description
              exception.error.error.fetch('backtrace').should == backtrace
              exception.error.error.fetch('types').should == types
              error_hash = exception.to_h
              error_hash.fetch('error').fetch('description').should == error_description
              error_hash.fetch('error').fetch('code').should == error_code
              error_hash.fetch('error').fetch('backtrace').should_not be_empty
              error_hash.fetch('error').fetch('types').should include(
                "VCAP::Services::Api::ServiceGatewayClient::ErrorResponse"
              )
              error_hash.fetch('error').fetch('error').should == {
                'backtrace' => backtrace,
                'types' => types
              }
            }
          end
        end
      end

      it_raises_an_exception_when(response_status: 404, exception: ServiceGatewayClient::NotFoundResponse)
      it_raises_an_exception_when(response_status: 503, exception: ServiceGatewayClient::GatewayInternalResponse)

      context 'when the response status is an unhandled, non-200' do
        it_raises_an_exception_when(response_status: 400, exception: ServiceGatewayClient::ErrorResponse)
        it_raises_an_exception_when(response_status: 500, exception: ServiceGatewayClient::ErrorResponse)
        it_raises_an_exception_when(response_status: 502, exception: ServiceGatewayClient::ErrorResponse)
        # ... you could test any other non-200 example not listed above

        context "when the response is not valid JSON" do
          let(:response_status_code) { 500 }
          let(:response_body) { "I am not JSON" }
          before do
            stub_request(:get, /.*/).to_return(status: response_status_code, body: response_body)
          end

          it "raises an UnexpectedResponse exception" do
            expect {
              http_client.perform_request(:get, url)
            }.to raise_error(ServiceGatewayClient::UnexpectedResponse) { |exception|
              exception.message.should =~ /status code: #{response_status_code}. response body: #{response_body}$/
            }
          end
        end
      end
    end
  end
end
