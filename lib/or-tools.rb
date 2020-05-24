# ext
require "or_tools/ext"

# modules
require "or_tools/comparison"
require "or_tools/comparison_operators"
require "or_tools/bool_var"
require "or_tools/cp_model"
require "or_tools/cp_solver"
require "or_tools/cp_solver_solution_callback"
require "or_tools/int_var"
require "or_tools/knapsack_solver"
require "or_tools/linear_expr"
require "or_tools/routing_model"
require "or_tools/sat_linear_expr"
require "or_tools/sat_int_var"
require "or_tools/solver"
require "or_tools/version"

# higher level interfaces
require "or_tools/sudoku"

module ORTools
  class Error < StandardError; end
end
