require_relative 'test_helper'

describe "Save Command" do
  include TestDsl
  let(:file_name) { 'save_output.txt' }

  describe "successful saving" do
    let(:file_contents) { File.read(file_name) }
    before do
      enter 'break 2', 'break 3 if true', 'catch NoMethodError', 'display 2 + 3', 'display 5 + 6',
        'set autoeval', 'set autolist',
        "save #{file_name}"
      debug_file 'save'
    end
    after do
      FileUtils.rm(file_name)
    end

    it "must save usual breakpoints" do
      file_contents.must_include "break #{fullpath('save')}:2"
    end

    it "must save conditinal breakpoints" do
      file_contents.must_include "break #{fullpath('save')}:3 if true"
    end

    it "must save catchpoints" do
      file_contents.must_include "catch NoMethodError"
    end

    # Not sure why it is suppressed, but this is like it is now.
    it "must not save displays" do
      file_contents.wont_include "display 2 + 3"
    end

    describe "saving settings" do
      it "must save autoeval" do
        file_contents.must_include "set autoeval on"
      end

      it "must save basename" do
        file_contents.must_include "set basename off"
      end

      it "must save debuggertesting" do
        file_contents.must_include "set debuggertesting on"
      end

      it "must save autolist" do
        file_contents.must_include "set autolist on"
      end

      it "must save autoirb" do
        file_contents.must_include "set autoirb off"
      end
    end

    it "must show a message about successful saving" do
      check_output_includes "Saved to '#{file_name}'"
    end

  end

  describe "without filename" do
    let(:file_contents) { File.read(interface.restart_file) }
    after { FileUtils.rm(interface.restart_file) }

    it "must fabricate a filename if not provided" do
      enter "save"
      debug_file 'save'
      file_contents.must_include "set autoirb"
    end

    it "must show a message where the file is saved" do
      enter "save"
      debug_file 'save'
      check_output_includes "Saved to '#{interface.restart_file}'"
    end
  end


  describe "Post Mortem" do
    let(:file_contents) { File.read(file_name) }
    after { FileUtils.rm(file_name) }
    it "must work in post-mortem mode" do
      enter 'cont', "save #{file_name}"
      debug_file 'post_mortem'
      file_contents.must_include "set autoirb off"
    end
  end

end
