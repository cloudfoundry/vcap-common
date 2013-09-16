module MessagePack

  #
  # MessagePack::Packer is an interface to serialize objects into an internal buffer,
  # which is a MessagePack::Buffer.
  #
  class Packer
    #
    # Creates a MessagePack::Packer instance.
    # See Buffer#initialize for supported options.
    #
    # @overload initialize(options={})
    #   @param options [Hash]
    #
    # @overload initialize(io, options={})
    #   @param io [IO]
    #   @param options [Hash]
    #   This packer writes serialzied objects into the IO when the internal buffer is filled.
    #   _io_ must respond to write(string) or append(string) method.
    #
    def initialize(*args)
    end

    #
    # Internal buffer
    #
    # @return MessagePack::Buffer
    #
    attr_reader :buffer

    #
    # Serializes an object into internal buffer.
    #
    # If it could not serialize the object, it raises
    # NoMethodError: undefined method `to_msgpack' for #<the_object>.
    #
    # @param obj [Object] object to serialize
    # @return [Packer] self
    #
    def write(obj)
    end

    alias pack write

    #
    # Serializes a nil object. Same as write(nil).
    #
    def write_nil
    end

    #
    # Write a header of an array whose size is _n_.
    # For example, write_array_header(1).write(true) is same as write([ true ]).
    #
    # @return [Packer] self
    #
    def write_array_header(n)
    end

    #
    # Write a header of an map whose size is _n_.
    # For example, write_map_header(1).write('key').write(true) is same as write('key'=>true).
    #
    # @return [Packer] self
    #
    def write_map_header(n)
    end

    #
    # Flushes data in the internal buffer to the internal IO. Same as _buffer.flush.
    # If internal IO is not set, it does nothing.
    #
    # @return [Packer] self
    #
    def flush
    end

    #
    # Makes the internal buffer empty. Same as _buffer.clear_.
    #
    # @return nil
    #
    def clear
    end

    #
    # Returns size of the internal buffer. Same as buffer.size.
    #
    # @return [Integer]
    #
    def size
    end

    #
    # Returns _true_ if the internal buffer is empty. Same as buffer.empty?.
    # This method is slightly faster than _size_.
    #
    # @return [Boolean]
    #
    def empty?
    end

    #
    # Returns all data in the buffer as a string. Same as buffer.to_str.
    #
    # @return [String]
    #
    def to_str
    end

    alias to_s to_str

    #
    # Returns content of the internal buffer as an array of strings. Same as buffer.to_a.
    # This method is faster than _to_str_.
    #
    # @return [Array] array of strings
    #
    def to_a
    end

    #
    # Writes all of data in the internal buffer into the given IO. Same as buffer.write_to(io).
    # This method consumes and removes data from the internal buffer.
    # _io_ must respond to write(data) method.
    #
    # @param io [IO]
    # @return [Integer] byte size of written data
    #
    def write_to(io)
    end
  end
end
