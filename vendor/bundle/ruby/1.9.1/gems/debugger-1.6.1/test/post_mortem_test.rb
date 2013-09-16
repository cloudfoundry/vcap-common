require_relative 'test_helper'

describe "Post Mortem" do
  include TestDsl

  it "must enter into port mortem mode" do
    enter 'cont'
    debug_file("post_mortem") { Debugger.post_mortem?.must_equal true }
  end

  it "must stop at the correct line" do
    enter 'cont'
    debug_file("post_mortem") { state.line.must_equal 8 }
  end

  it "must exit from post mortem mode after stepping command" do
    enter 'cont', 'break 12', 'cont'
    debug_file("post_mortem") { Debugger.post_mortem?.must_equal false }
  end

  it "must save the raised exception" do
    enter 'cont'
    debug_file("post_mortem") { Debugger.last_exception.must_be_kind_of RuntimeError }
  end
end
