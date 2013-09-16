require_relative 'test_helper'

describe "Set Command" do
  include TestDsl

  describe "setting to on" do
    temporary_change_hash_value(Debugger::Command.settings, :autolist, 0)

    it "must set a setting to on" do
      enter 'set autolist on'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 1
    end

    it "must set a setting to on by 1" do
      enter 'set autolist 1'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 1
    end

    it "must set a setting to on by default" do
      enter 'set autolist'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 1
    end

    it "must set a setting using shortcut" do
      enter 'set autol'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 1
    end
  end

  describe "setting to off" do
    temporary_change_hash_value(Debugger::Command.settings, :autolist, 1)

    it "must set a setting to off" do
      enter 'set autolist off'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 0
    end

    it "must set a setting to off by 0" do
      enter 'set autolist 0'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 0
    end

    it "must set a setting to off by 'no' suffix" do
      enter 'set noautolist'
      debug_file 'set'
      Debugger::Command.settings[:autolist].must_equal 0
    end
  end

  describe "messages" do
    temporary_change_hash_value(Debugger::Command.settings, :autolist, 0)

    it "must show a message after setting" do
      enter 'set autolist on'
      debug_file 'set'
      check_output_includes "autolist is on"
    end
  end

  describe "debuggertesting" do
    temporary_change_hash_value(Debugger::Command.settings, :debuggertesting, false)
    before { $rdebug_state = nil }
    after { $rdebug_state = nil }

    it "must set $rdebug_context if debuggersetting is on" do
      enter 'set debuggertesting', 'break 3', 'cont'
      debug_file('set') { state.must_be_kind_of Debugger::CommandProcessor::State }
    end

    it "must set basename on too" do
      temporary_change_hash_value(Debugger::Command.settings, :basename, false) do
        enter 'set debuggertesting', 'show basename'
        debug_file('set')
        check_output_includes "basename is on"
      end
    end

    it "must not set $rdebug_context if debuggersetting is off" do
      enter 'set nodebuggertesting', 'break 3', 'cont'
      debug_file('set') { state.must_be_nil }
    end
  end

  describe "history" do
    describe "save" do
      it "must set history save to on" do
        enter 'set history save on'
        debug_file 'set'
        interface.history_save.must_equal true
      end

      it "must show a message" do
        enter 'set history save on'
        debug_file 'set'
        check_output_includes "Saving of history save is on"
      end

      it "must set history save to off" do
        enter 'set history save off'
        debug_file 'set'
        interface.history_save.must_equal false
      end
    end

    describe "size" do
      it "must set history size" do
        enter 'set history size 250'
        debug_file 'set'
        interface.history_length.must_equal 250
      end

      it "must show a message" do
        enter 'set history size 250'
        debug_file 'set'
        check_output_includes "Debugger history size is 250"
      end
    end

    describe "filename" do
      it "must set history filename" do
        enter 'set history filename .debugger-hist'
        debug_file 'set'
        interface.histfile.must_equal File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", '.debugger-hist')
      end

      it "must show a message" do
        enter 'set history filename .debugger-hist'
        debug_file 'set'
        history_filename = File.join(ENV["HOME"] || ENV["HOMEPATH"] || ".", ".debugger-hist")
        check_output_includes "The filename in which to record the command history is '#{history_filename}'"
      end
    end

    it "must show an error message if used wrong subcommand" do
      enter 'set history bla 2'
      debug_file 'set'
      check_output_includes "Invalid history parameter bla. Should be 'filename', 'save' or 'size'"
    end

    it "must show an error message if provided only one argument" do
      enter 'set history save'
      debug_file 'set'
      check_output_includes "Need two parameters for 'set history'; got 1"
    end
  end

  describe "width" do
    temporary_change_hash_value(Debugger::Command.settings, :width, 20)

    it "must set ENV['COLUMNS'] by the 'set width' command" do
      old_columns = ENV["COLUMNS"]
      begin
        enter 'set width 10'
        debug_file 'set'
        ENV["COLUMNS"].must_equal '10'
      ensure
        ENV["COLUMNS"] = old_columns
      end
    end
  end


  describe "Post Mortem" do
    temporary_change_hash_value(Debugger::Command.settings, :autolist, 0)
    it "must work in post-mortem mode" do
      enter 'cont', "set autolist on"
      debug_file 'post_mortem'
      check_output_includes "autolist is on"
    end
  end

end
