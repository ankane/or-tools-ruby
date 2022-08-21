require_relative "test_helper"

class ORToolsTest < Minitest::Test
  def test_lib_version
    assert_match(/\A\d+\.\d+\.\d+\z/, ORTools.lib_version)
  end
end
