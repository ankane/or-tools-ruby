require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "stringio"
require "time"

class Minitest::Test
  def setup
    @output = StringIO.new("")
  end

  # not ideal, but useful for testing examples
  def puts(*args)
    super(*args) if ENV["VERBOSE"]
    @output.puts(*args)
  end

  def assert_output(expected)
    assert_equal expected, @output.string
  end
end
