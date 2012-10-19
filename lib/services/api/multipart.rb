# Copyright (c) 2009-2011 VMware, Inc.
require 'eventmachine'
require 'em-http-request'

# monkey-patch for em-http-request to support multipart file upload

module EventMachine
  class StreamUploadIO
    attr_reader :args, :filename, :basename, :size, :content_type
    def initialize(filename, content_type, args={})
      # disable http chunking
      @args = args.merge({:http_chunks => false})
      @filename = filename
      # FIXME how to catch exception and log it
      begin
        @basename = File.basename(filename)
        @size = File.size(filename)
      rescue => e
        # size == 0, the part will be injected
        @size = 0
      end
      @content_type = content_type
    end

    def add_extra_size(extra_size)
      @size += extra_size
    end

    def length
      @size
    end

    def stream_file_data
      true
    end
  end

  module Part
    def self.create(boundary, k, v)
      if v.respond_to?(:stream_file_data)
        FilePart.new(boundary, k, v)
      else
        ParamPart.new(boundary, k, v)
      end
    end

    def to_io
      @io
    end

    def length
      @io.size
    end

    def send_part(conn, parts, idx)
    end

    def get_next_part(parts, idx)
      next_idx = idx.to_i + 1
      if parts && next_idx < parts.size && next_idx >=0
        next_part = parts[next_idx]
      else
        nil
      end
      next_part
    end

    def send_next_part(conn, parts, idx)
      next_part = get_next_part(parts, idx)
      next_part.send_part(conn, parts, idx+1) if next_part
    end

  end

  class ParamPart
    include Part
    def initialize(boundary, name, value)
      @boundary = boundary
      @name = name
      part = ''
      part << "--#{@boundary}\r\n"
      part << "Content-Disposition: form-data; name=\"#{@name.to_s}\"\r\n"
      part << "\r\n"
      part << "#{value.to_s}\r\n"
      @io = StringIO.new(part)
    end

    def send_part(conn, parts, idx)
      conn.send_data @io.string if conn
      send_next_part(conn, parts, idx)
    end
  end

  class EpiloguePart
    include Part
    def initialize(boundary)
      @io = StringIO.new("--#{boundary}--\r\n") #\r\n or \r\n\r\n
    end

    def send_part(conn, parts, idx)
      conn.send_data @io.string if conn
      # this part should be the last part
    end
  end

  class FilePart
    include Part
    def initialize(boundary, name, upload_io)
      @boundary = boundary
      @name = name
      @io = upload_io
      @part = ''
      @part << "--#{boundary}\r\n"
      @part << "Content-Disposition: form-data; name=\"#{name.to_s}\"; filename=\"#{@io.filename}\"\r\n"
      @part << "Content-Length: #{@io.size}\r\n"
      @part << "Content-Type: #{@io.content_type}\r\n"
      @part << "Content-Transfer-Encoding: binary\r\n"
      @part << "\r\n"
      @end_part ="\r\n"
      @io.add_extra_size(@part.size + @end_part.size)
    end

    def send_part(conn, parts, idx)
      conn.send_data @part
      streamer = EM::FileStreamer.new(conn, @io.filename, @io.args)
      streamer.callback {
        conn.send_data @end_part
        send_next_part(conn, parts, idx)
      }
    end
  end

  class Multipart
    DEFAULT_BOUNDARY = "-----------RubyEMMultiPartPost"
    attr_reader :parts, :ps, :content_type, :content_length, :boundary, :headers
    def initialize(params, headers={}, boundary=DEFAULT_BOUNDARY)
      @parts = params.map{ |k,v| Part.create(boundary, k, v) }
      @parts << EpiloguePart.new(boundary)
      # inject the part with length = 0
      @ps = @parts.select{ |part| part.length > 0 }
      @content_type = "multipart/form-data; boundary=#{boundary}"
      @content_length = 0
      @parts.each do |part|
        @content_length += part.length
      end
      @boundary = boundary
      @headers = headers
    end

    def send_body(conn)
      if conn && conn.error.nil? && @parts.size > 0
        part = @parts.first
        part.send_part(conn, @parts, 0)
      end
    end
  end
end

## Support to streaming the file when sending body
## TODO FIXME this patch whether depends on specified version???
## FIXME: yes it depends on a very specific beta version, yuck
## FIXME: a less gross alternative is to stream out the request body to disk,
## and use the :file option to instruct em-http-request to stream the body
## from disk
module EventMachine
  class HttpClient
    alias_method :original_send_request, :send_request
    def multipart_request?
      (@req.method == 'POST' or @req.method == 'PUT') and @options[:multipart]
    end

    def send_request(head, body)
      unless multipart_request?
        original_send_request(head, body)
      else
        body = normalize_body(body)
        multipart = @options[:multipart]
        query = @options[:query]

        head['content-length'] = multipart.content_length
        head['content-type'] = multipart.content_type
        extra_headers = {}
        extra_headers = multipart.headers.reject { |k, v| %w(content-length content-type).include?(k.to_s.downcase) }
        head.merge!  extra_headers

        request_header ||= encode_request(@req.method, @req.uri, query, @conn.opts.proxy)
        request_header << encode_headers(head)
        request_header << CRLF
        @conn.send_data request_header

        multipart.send_body(@conn)
      end
    end
  end
end
