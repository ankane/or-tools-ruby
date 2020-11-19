require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "time"

class Minitest::Test
  def ci?
    ENV["CI"]
  end
end
