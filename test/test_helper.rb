require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "stringio"
require "time"

class Minitest::Test
  def setup
    @output = StringIO.new(+"")
    @output_checked = false

    GC.stress = true if stress?
  end

  def teardown
    GC.stress = false if stress?

    if !@output.string.empty? && !@output_checked
      warn "#{self.class.name}##{name}: Captured output. Use VERBOSE=1 to show."
    end
  end

  # not ideal, but useful for testing examples
  def puts(*args)
    super(*args) if ENV["VERBOSE"]
    @output.puts(*args)
  end

  def assert_output(expected)
    assert_equal expected, @output.string
    @output_checked = true
  end

  def stress?
    ENV["STRESS"]
  end
end
