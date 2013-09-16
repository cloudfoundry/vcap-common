require_relative 'test_helper'

describe "Jump Command" do
  include TestDsl

  describe "successful" do
    it "must jump with absolute line number" do
      enter 'break 6', 'cont', "jump 8 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 8 }
    end

    describe "jumping to the same line" do
      it "must jump to the same line" do
        enter 'break 6', 'cont', "jump 6 #{fullpath('jump')}"
        debug_file('jump') { state.line.must_equal 6 }
      end

      it "must show show the same position" do
        enter 'break 6', 'cont', "jump 6 #{fullpath('jump')}"
        debug_file('jump')
        check_output_includes "#{fullpath('jump')}:6\nb = 3"
      end
    end

    it "must not initialize skipped variables during jump" do
      enter 'break 6', 'cont', "jump 8 #{fullpath('jump')}", 'next'
      enter 'var local'
      debug_file('jump')
      check_output_includes /a = 2\nb = nil\nc = nil\nd = 5\ne = nil\nf = nil/
    end

    it "must jump with relative line number (-)" do
      enter 'break 8', 'cont', "jump -2 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 6 }
    end

    it "must jump with relative line number (+)" do
      enter 'break 8', 'cont', "jump +2 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 10 }
    end

    it "must show message after jump" do
      enter 'break 6', 'cont', "jump 8 #{fullpath('jump')}"
      debug_file('jump')
      check_output_includes "#{fullpath('jump')}:8\nd = 5"
    end
  end

  describe "errors" do
    it "must show an error if line number is invalid" do
      enter 'jump bla'
      debug_file('jump')
      check_output_includes "Bad line number: bla", interface.error_queue
    end

    it "must show an error if line number is not specified" do
      enter 'jump'
      debug_file('jump')
      check_output_includes "'jump' must be followed by a line number", interface.error_queue
    end

    describe "when there is no active code in specified line" do
      it "must not jump to there" do
        enter "jump 13 #{fullpath('jump')}"
        debug_file('jump') { state.line.must_equal 3 }
      end

      it "must show an error" do
        enter "jump 13 #{fullpath('jump')}"
        debug_file('jump')
        check_output_includes "Couldn't find active code at #{fullpath('jump')}:13", interface.error_queue
      end
    end
  end


  describe "Post Mortem" do
    # TODO: This test fails with "Segmentation fault". Probably need to fix it somehow, or forbid this
    # command in the post mortem mode. Seems like state.context.frame_file and state.context.frame_line
    # cause that.
    it "must work in post-mortem mode"# do
    #  enter 'cont', 'jump 12'
    #  debug_file 'post_mortem'
    #  pi
    #end
  end


end
