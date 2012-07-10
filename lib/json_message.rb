# Copyright (c) 2009-2011 VMware, Inc
require 'rubygems'
require 'yajl'
require 'membrane'

class JsonMessage
  # Base error class that all other JsonMessage related errors should
  # inherit from
  class Error < StandardError
  end

  # Fields not defined properly.
  class DefinitionError < Error
  end

  # Failed to parse json during +decode+
  class ParseError < Error
  end

  # One or more field's values didn't match their schema
  class ValidationError < Error
    def initialize(field_errs)
      @field_errs = field_errs
    end

    def to_s
      err_strs = @field_errs.map{|f, e| "Field: #{f}, Error: #{e}"}
      err_strs.join(', ')
    end
  end

  class Field
    attr_reader :name, :schema, :required, :default

    def initialize(name, schema, required = true, default = nil)
      if required && default
        msg = "Cannot define a default value: #{default}"
        msg << " for the required field: #{name}."
        raise DefinitionError.new(msg)
      end

      @name = name
      if schema.is_a?(Membrane::Schema::Base)
        @schema = schema
      else
        @schema = Membrane::SchemaParser.parse { schema }
      end

      @required = required

      if default
        begin
          @schema.validate(default)
        rescue Membrane::SchemaValidationError => e
          raise ValidationError.new( { name => e.message } )
        end
      end

      @default = default
    end
  end

  class << self
    attr_reader :fields

    def schema(&blk)
      instance_eval &blk
    end

    def decode(json)
      begin
        dec_json = Yajl::Parser.parse(json)
      rescue => e
        raise ParseError, e.to_s
      end

      from_decoded_json(dec_json)
    end

    def from_decoded_json(dec_json)
      raise ParseError, "Decoded JSON cannot be nil" unless dec_json

      errs = {}

      # Treat null values as if the keys aren't present. This isn't as strict
      # as one would like, but conforms to typical use cases.
      dec_json.delete_if {|k, v| v == nil}

      # Collect errors by field
      @fields.each do |name, field|
        err = nil
        name_s = name.to_s
        if dec_json.has_key?(name_s)
          begin
            field.schema.validate(dec_json[name_s])
          rescue Membrane::SchemaValidationError => e
            err = e.message
          end
        elsif field.required
          err = "Missing field #{name}"
        end
        errs[name] = err if err
      end

      raise ValidationError.new(errs) unless errs.empty?

      new(dec_json)
    end

    def required(field_name, schema = Membrane::Schema::ANY)
      define_field(field_name, schema, true)
    end

    def optional(field_name, schema = Membrane::Schema::ANY, default = nil)
      define_field(field_name, schema, false, default)
    end

    protected

    def define_field(name, schema, required, default = nil)
      name = name.to_sym

      @fields ||= {}
      @fields[name] = Field.new(name, schema, required, default)

      define_method name.to_sym do
        set_default(name)
        @msg[name]
      end

      define_method "#{name}=".to_sym do |value|
        set_field(name, value)
      end
    end
  end

  def initialize(fields={})
    @msg = {}
    fields.each {|k, v| set_field(k, v)}
    set_defaults
  end

  def encode
    if self.class.fields
      set_defaults
      missing_fields = {}
      self.class.fields.each do |name, field|
        unless (!field.required || @msg.has_key?(name))
          missing_fields[name] = "Missing field #{name}"
        end
      end
      raise ValidationError.new(missing_fields) unless missing_fields.empty?
    end

    Yajl::Encoder.encode(@msg)
  end

  def extract
    @msg.dup.freeze
  end

  protected

  def set_field(field, value)
    field = field.to_sym
    unless self.class.fields && self.class.fields.has_key?(field)
      raise ValidationError.new( { field => "Unknown field: #{field}" } )
    end

    begin
      self.class.fields[field].schema.validate(value)
    rescue Membrane::SchemaValidationError => e
      raise ValidationError.new( { field => e.message } )
    end

    @msg[field] = value
  end

  def set_defaults
    if self.class.fields
      self.class.fields.each do |name, field|
        set_default(name)
      end
    end
  end

  def set_default(name)
    if !@msg.include?(name)
      if self.class.fields
        if self.class.fields.include?(name) && self.class.fields[name].default
          @msg[name] = self.class.fields[name].default
        end
      end
    end
  end
end