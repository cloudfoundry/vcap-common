# Copyright (c) 2009-2012 VMware, Inc.
require 'net/http'
require 'net/http/post/multipart'
require 'mime/types'
require 'uri'

require 'eventmachine'
require 'services/api/const'
require 'services/api/messages'
require 'services/api/multipart'

module VCAP
  module Services
    module Api
    end
  end
end

module VCAP::Services::Api
  class SDSClient

    class SDSErrorResponse < StandardError; end
    class UnexpectedResponse < StandardError; end

    def initialize(url, upload_token, timeout=60, opts={})
      @url = url
      # the options hash can't be specified in Ruby if caller omits timeout...
      raise ArgumentError unless timeout.respond_to?(:to_f)
      @timeout = timeout
      @upload_hdrs = {
        'Content-Type' => 'multipart/form-data',
        SDS_UPLOAD_TOKEN_HEADER => upload_token
      }
    end

    def import_from_data(args)
      resp = perform_multipart_upload("/serialized/#{args[:service]}/#{args[:service_id]}/serialized/data", args[:msg])
      SerializedURL.decode(resp)
    end

    protected

    def perform_multipart_upload(path, file_path)
      # upload file using multipart/form data
      result = nil
      uri = URI.parse(@url)

      mime_types = MIME::Types.type_for(file_path) || []
      mime_types << "application/octet-stream" if mime_types.empty?

      if EM.reactor_thread?
        payload = {:_method => 'put', :data_file => EM::StreamUploadIO.new(file_path, mime_types[0])}
        multipart = EM::Multipart.new(payload, @upload_hdrs)
        url = URI.parse(uri.to_s + path)
        http = AsyncHttpMultiPartUpload.fibered(url, @timeout, multipart)
        raise UnexpectedResponse, "Error uploading #{file_path} to serialized_data_server #{@url}: #{http.error}" unless http.error.empty?
        code = http.response_header.status.to_i
        body = http.response
      else
        payload = {:_method => 'put', :data_file => UploadIO.new(file_path, mime_types[0])}
        req = Net::HTTP::Post::Multipart.new(path, payload, @upload_hdrs)
        resp = Net::HTTP.new(uri.host, uri.port).start do |http|
          http.request(req)
        end
        code = resp.code.to_i
        body = resp.body
      end
      case code
      when 200
        body
      when 400
        raise SDSErrorResponse, "Fail to upload the file to serialization_data_server."
      when 403
        raise SDSErrorResponse, "You are forbidden to access serialization_data_server."
      when 404
        raise SDSErrorResponse, "Not found in serialization_data_server."
      when 501
        raise SDSErrorResponse, "Serialized data file is recognized, but file not found in serialization_data_server."
      else
        raise UnexpectedResponse, "Unexpected exception in serialization_data_server: #{(uri.to_s + path)} #{code} #{body}"
      end
    end
  end
end
