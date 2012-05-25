# Copyright (c) 2009-2011 VMware, Inc.
require 'spec_helper'

describe SortedSet do
  DEFAULT_SET = [-4, -1, 0, 1, 4, 6, 9]

  it 'should properly handle empty sorted set' do
    set = SortedSet.new
    SortedSet.from_int_array(set.to_int_array).should == set
  end

  it 'should properly handle sorted set with one item' do
    set = SortedSet.new([1])
    SortedSet.from_int_array(set.to_int_array).should == set
  end

  it 'should properly handle sorted set' do
    set = SortedSet.new(DEFAULT_SET)
    SortedSet.from_int_array(set.to_int_array).should == set
  end

  it 'should properly handle random sorted set' do
    set = SortedSet.new
    20.times do
      set << Random.rand(100)
    end
    SortedSet.from_int_array(set.to_int_array).should == set
  end
end
