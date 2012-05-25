# Copyright (c) 2009-2012 VMware, Inc.
#
# These two methods provide support for transfering an integer sorted set to/from
# array. When encoded into JSON format, the to_int_array method is space efficient
# comparing to the native to_a method of sorted set.
#
# For example, the following set
# [12345, 12456, 13457, 13567, 14203, 14214]
#
# After encoded by to_int_array, it becomes
# [12345, 111, 1, 90, 636, 11]
#
# The JSON format will save lots of space
#

require 'set'

class SortedSet
  def to_int_array
    array = []

    former = 0
    self.each do |i|
      array << i - former
      former = i
    end

    array
  end

  def self.from_int_array(array)
    set = SortedSet.new

    current = 0
    array.each do |i|
      current += i
      set << current
    end

    set
  end
end
