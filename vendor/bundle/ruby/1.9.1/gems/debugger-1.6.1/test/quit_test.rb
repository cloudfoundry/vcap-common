require_relative 'test_helper'

describe "Quit Command" do
  include TestDsl

  it "must quit if user confirmed" do
    Debugger::QuitCommand.any_instance.expects(:exit!)
    enter 'quit', 'y'
    debug_file 'quit'
    check_output_includes "Really quit? (y/n)", interface.confirm_queue
  end

  it "must not quit if user didn't confirm" do
    Debugger::QuitCommand.any_instance.expects(:exit!).never
    enter 'quit', 'n'
    debug_file 'quit'
    check_output_includes "Really quit? (y/n)", interface.confirm_queue
  end

  it "must quit immediatly if used with !" do
    Debugger::QuitCommand.any_instance.expects(:exit!)
    enter 'quit!'
    debug_file 'quit'
    check_output_doesnt_include "Really quit? (y/n)", interface.confirm_queue
  end

  it "must quit immediatly if used with 'unconditionally'" do
    Debugger::QuitCommand.any_instance.expects(:exit!)
    enter 'quit unconditionally'
    debug_file 'quit'
    check_output_doesnt_include "Really quit? (y/n)", interface.confirm_queue
  end

  it "must finalize interface before quitting" do
    Debugger::QuitCommand.any_instance.stubs(:exit!)
    interface.expects(:finalize)
    enter 'quit!'
    debug_file 'quit'
  end

  it "must quit if used 'exit' alias" do
    Debugger::QuitCommand.any_instance.expects(:exit!)
    enter 'exit!'
    debug_file 'quit'
  end

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      Debugger::QuitCommand.any_instance.expects(:exit!)
      enter 'cont', 'exit!'
      debug_file 'post_mortem'
    end
  end

end
