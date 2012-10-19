# Copyright (c) 2009-2012 VMware, Inc.
require 'net/http'
require 'net/http/post/multipart'
require 'mime/types'
require 'uri'

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

    # @return [#request] an object that has responds to #request and returns a
    #   2-element array of [code, body]
    attr_reader :requester

    # FIXME: Move all call sites to either not specify timeout or put it in
    # options hash. I hate doing overloading in Ruby and Python, but this is
    # for backwards compatibility
    # @overload new(url, token, timeout=60, opts={:requester => AsyncHttpMultiPartUpload})
    # @overload new(url, token, opts)
    # @overload new(url, token, timeout)
    def initialize(url, upload_token, timeout=60,
                   opts={:requester => AsyncHttpMultiPartUpload})
      @url = url
      if timeout.respond_to?(:to_f)
        @timeout = timeout
      else
        # the 3rd arg is actually opts...
        opts = timeout
        @timeout = opts.fetch(:timeout, 60)
      end
      @requester = opts[:requester] || AsyncHttpMultiPartUpload
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

      if EM.reactor_running?
        url = URI.join(@url, path)
        code, body = requester.request(
          "PUT",
          url,
          file_path,
          :headers => @upload_hdrs,
          :timeout => @timeout,
        )
      else
        code, body = SynchronousMultipartUpload.request(
          "PUT",
          url,
          file_path,
          :headers => @upload_hdrs,
        )
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
