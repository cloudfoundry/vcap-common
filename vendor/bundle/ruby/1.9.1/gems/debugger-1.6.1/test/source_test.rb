require_relative 'test_helper'

describe "Source Command" do
  include TestDsl

  let(:filename) { 'source_example.txt' }
  before do
    File.open(filename, 'w') do |f|
      f.puts 'break 2'
      f.puts 'break 3 if true'
    end
  end
  after do
    FileUtils.rm(filename)
  end

  it "must run commands from file" do
    enter "source #{filename}"
    debug_file 'source' do
      Debugger.breakpoints[0].pos.must_equal 2
      Debugger.breakpoints[1].pos.must_equal 3
      Debugger.breakpoints[1].expr.must_equal "true"
    end
  end

  it "must be able to use shortcut" do
    enter "so #{filename}"
    debug_file('source') { Debugger.breakpoints[0].pos.must_equal 2 }
  end

  it "must show an error if file is not found" do
    enter "source blabla"
    debug_file 'source'
    check_output_includes /Command file '.*blabla' is not found/, interface.error_queue
  end

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      enter 'cont', "so #{filename}"
      debug_file('post_mortem') { Debugger.breakpoints[0].pos.must_equal 2 }
    end
  end

end
