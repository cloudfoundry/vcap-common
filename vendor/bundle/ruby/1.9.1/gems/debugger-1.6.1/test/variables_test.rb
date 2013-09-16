require_relative 'test_helper'

describe "Variables Command" do
  include TestDsl
  temporary_change_hash_value(Debugger::Command.settings, :width, 40)

  describe "class variables" do
    it "must show variables" do
      enter 'break 19', 'cont', 'var class'
      debug_file 'variables'
      check_output_includes '@@class_c = 3'
    end

    it "must be able to use shortcut" do
      enter 'break 19', 'cont', 'v cl'
      debug_file 'variables'
      check_output_includes '@@class_c = 3'
    end
  end

  describe "constants" do
    it "must show constants" do
      enter 'break 25', 'cont', 'var const VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST = foo'
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v co VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST = foo'
    end

    it "must show an error message if the given object is not a Class or Module" do
      enter 'break 25', 'cont', 'var const v'
      debug_file 'variables'
      check_output_includes "Should be Class/Module: v", interface.error_queue
    end
  end

  describe "globals" do
    it "must show global variables" do
      enter 'break 25', 'cont', 'var global'
      debug_file 'variables'
      check_output_includes /\$glob = 100/
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v g'
      debug_file 'variables'
      check_output_includes /\$glob = 100/
    end
  end

  describe "instance variables" do
    it "must show instance variables of the given object" do
      enter 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes /@inst_a = 1\n@inst_b = 2/
    end

    it "must show instance variables by object id" do
      enter 'break 25', 'cont', ->{"var instance #{eval('"%#+x" % v.object_id', binding)}"}
      debug_file 'variables'
      check_output_includes /@inst_a = 1/
    end

    it "must show instance variables of self" do
      enter 'break 11', 'cont', 'var instance'
      debug_file 'variables'
      check_output_includes /@inst_a = 1\n@inst_b = 2/
    end

    it "must show instance variables" do
      enter 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes /@inst_a = 1\n@inst_b = 2/
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v ins v'
      debug_file 'variables'
      check_output_includes /@inst_a = 1\n@inst_b = 2/
    end

    it "must cut long variable values according to :width setting" do
      temporary_change_hash_value(Debugger::Command.settings, :width, 20) do
        enter 'break 25', 'cont', 'var instance v'
        debug_file 'variables'
        check_output_includes /@inst_c = "1111111111111111\.\.\.\n/
      end
    end

    it "must show fallback message if value doesn't have #to_s or #inspect methods" do
      enter 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes /@inst_d = \*Error in evaluation\*/
    end
  end

  describe "local variables" do
    it "must show local variables" do
      enter 'break 17', 'cont', 'var local'
      debug_file 'variables'
      check_output_includes /a = 4\nb = nil\ni = 1/
    end

    it "must not show self in variables if the self is 'main'" do
      enter 'break 24', 'cont', 'var local'
      debug_file 'variables'
      check_output_doesnt_include /self =/
    end

    it "must show self in variables if the self is not 'main'" do
      enter 'break 17', 'cont', 'var local'
      debug_file 'variables'
      check_output_includes /self = #<VariablesExample:[^>]+>/
    end
  end

  # TODO: Need to write tests for 'var ct' command, but I can't install the 'ruby-internal' gem
  # on my machine, it fails to build gem native extension.

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      enter 'cont', 'var local'
      debug_file 'post_mortem'
      check_output_includes "self = blabla\nx = nil\nz = 4"
    end
  end

end
