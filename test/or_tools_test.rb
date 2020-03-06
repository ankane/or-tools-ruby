require_relative "test_helper"

class ORToolsTest < Minitest::Test
  def test_lib_version
    assert ORTools.lib_version
  end
end
