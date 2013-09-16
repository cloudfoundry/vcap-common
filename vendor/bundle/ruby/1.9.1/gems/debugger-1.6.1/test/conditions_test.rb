require_relative 'test_helper'

describe "Conditions" do
  include TestDsl

  describe "setting condition" do
    before { enter 'break 3' }

    describe "successfully" do
      before { enter ->{"cond #{breakpoint.id} b == 5"}, "cont" }
      it "must stop at the breakpoint if condition is true" do
        debug_file('conditions') { state.line.must_equal 3 }
      end

      it "must assign that expression to breakpoint" do
        debug_file('conditions') { breakpoint.expr.must_equal "b == 5" }
      end

      it "must show a successful message" do
        id = nil
        debug_file('conditions') { id = breakpoint.id }
        check_output_includes "Condition 'b == 5' is set for the breakpoint #{id}"
      end
    end

    it "must not stop at the breakpoint if condition is false" do
      enter "break 4", ->{"cond #{breakpoint.id} b == 3"}, "cont"
      debug_file('conditions') { state.line.must_equal 4 }
    end

    it "must ignore the condition if its syntax is incorrect" do
      enter "break 3", ->{"cond #{breakpoint.id} b =="}, "break 4", "cont"
      debug_file('conditions') { state.line.must_equal 4 }
    end

    it "must assign the expression to the breakpoint anyway, even if its syntax is incorrect" do
      enter "break 3", ->{"cond #{breakpoint.id} b =="}, "break 4", "cont"
      debug_file('conditions') { breakpoint.expr.must_equal "b ==" }
    end

    it "must work with full command name too" do
      enter ->{"condition #{breakpoint.id} b == 5"}, "cont"
      debug_file('conditions') { state.line.must_equal 3 }
    end
  end


  describe "removing conditions" do
    before { enter "break 3 if b == 3", "break 4", ->{"cond #{breakpoint.id}"}, "cont" }

    it "must remove the condition from the breakpoint" do
      debug_file('conditions') { breakpoint.expr.must_be_nil }
    end

    it "must not stop on the breakpoint" do
      debug_file('conditions') { state.line.must_equal 3 }
    end

    it "must show a successful message" do
      id = nil
      debug_file('conditions') { id = breakpoint.id }
      check_output_includes "Condition is cleared for the breakpoint #{id}"
    end
  end


  describe "errors" do
    it "must not set breakpoint condition if breakpoint id is incorrect" do
      enter 'break 3', 'cond 8 b == 3', 'cont'
      debug_file('conditions') { state.line.must_equal 3 }
    end

    it "must show error if there are no breakpoints" do
      enter 'cond 1 true'
      debug_file('conditions')
      check_output_includes "No breakpoints have been set"
    end
  end


  describe "Post Mortem" do
    it "must be able to set conditions in post-mortem mode" do
      enter 'cont', 'break 12', ->{"cond #{breakpoint.id} true"}, 'cont'
      debug_file("post_mortem") { state.line.must_equal 12 }
    end
  end

end
