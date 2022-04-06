require_relative "test_helper"

class ORToolsTest < Minitest::Test
  def test_lib_version
    # TODO include patch version in 0.8.0
    assert_match(/\A\d+\.\d+\z/, ORTools.lib_version)
  end
end
