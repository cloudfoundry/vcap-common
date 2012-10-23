# Copyright (c) 2009-2011 VMware, Inc.
require 'eventmachine'
require 'em-http-request'
require 'fiber'
require 'httpclient'

require 'services/api/const'

module VCAP
  module Services
    module Api
    end
  end
end

module VCAP::Services::Api
  class AsyncHttpRequest
    class << self
      def new(url, token, verb, timeout, msg=VCAP::Services::Api::EMPTY_REQUEST)

        req = {
          :head => {
            VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
            'Content-Type' => 'application/json',
          },
          :body => msg.encode,
        }
        if timeout
          EM::HttpRequest.new(url, :inactivity_timeout => timeout).send(verb.to_sym, req)
        else
          EM::HttpRequest.new(url).send(verb.to_sym, req)
        end
      end

      def request(url, token, verb, timeout, msg=VCAP::Services::Api::EMPTY_REQUEST)
        req = new(url, token, verb, timeout, msg)
        f = Fiber.current
        req.callback { f.resume(req) }
        req.errback  { f.resume(req) }
        http = Fiber.yield
        raise UnexpectedResponse, "Error sending request #{msg.extract.to_json} to gateway #{@url}: #{http.error}" unless http.error.empty?
        code = http.response_header.status.to_i
        body = http.response
        [code, body]
      end
    end
  end

  module SynchronousHttpRequest
    def self.request(url, token, verb, timeout, msg=VCAP::Services::Api::EMPTY_REQUEST)
      header = {
        VCAP::Services::Api::GATEWAY_TOKEN_HEADER => token,
        'Content-Type' => 'application/json',
      }
      body = msg.encode
      client = HTTPClient.new
      msg = client.request(verb.to_sym, url, :body => body, :header => header)
      [msg.code, msg.body]
    end
  end

  class AsyncHttpMultiPartUpload
    class << self
      def new(url, timeout, multipart, head={})
        req = {
          :head => head,
          :body => "",
          :multipart => multipart
        }

        if timeout
          EM::HttpRequest.new(url, :inactivity_timeout => timeout).post req
        else
          EM::HttpRequest.new(url).post req
        end
      end

      def fibered(url, timeout, multipart, head={})
        req = new(url, timeout, multipart, head)
        f = Fiber.current
        req.callback { f.resume(req) }
        req.errback {f.resume(req)}
        Fiber.yield
      end

      # @param ["PUT", "POST"] method the HTTP verb for the request, currently
      #     ignored and an emulated PUT is always used
      # @param [URI::Generic] url
      # @param [String] file_path the data file to be imported to SDS
      # @param [Hash] opts
      # @option opts [Hash] :headers
      # @option opts [Numeric] :timeout
      # @return [[code, body]]
      def request(method, url, file_path, opts = {})
        mime_types = MIME::Types.type_for(file_path) || []
        mime_types << "application/octet-stream" if mime_types.empty?

        payload = {:_method => 'put', :data_file => EM::StreamUploadIO.new(file_path, mime_types[0])}
        multipart = EM::Multipart.new(payload, opts[:headers])
        # url = URI.parse(uri.to_s + path)
        http = fibered(url, opts[:timeout], multipart)
        raise UnexpectedResponse, "Error uploading #{file_path} to serialized_data_server #{@url}: #{http.error}" unless http.error.empty?
        code = http.response_header.status.to_i
        body = http.response
        [code, body]
      end
    end
  end

  class SynchronousMultipartUpload
      # @param ["PUT", "POST"] method the HTTP verb for the request, currently
      #     ignored and an emulated PUT is always used
      # @param [URI::Generic] url
      # @param [String] file_path the data file to be imported to SDS
      # @param [Hash] opts
      # @option opts [Hash] :headers
      # @return [[code, body]]
    def self.request(method, url, file_path, opts = {})
      mime_types = MIME::Types.type_for(file_path) || []
      mime_types << "application/octet-stream" if mime_types.empty?

      payload = {:_method => 'put', :data_file => UploadIO.new(file_path, mime_types[0])}
      req = Net::HTTP::Post::Multipart.new(url.request_uri, payload, opts[:headers])
      resp = Net::HTTP.new(url.host, url.port).start do |http|
        http.request(req)
      end
      [resp.code.to_i, resp.body]
    end
  end
end
