# ext
require "or_tools/ext"

# modules
require "or_tools/cp_solver"
require "or_tools/knapsack_solver"
require "or_tools/routing_model"
require "or_tools/version"

module ORTools
  class Error < StandardError; end
end
