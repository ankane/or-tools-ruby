# ext
require "or_tools/ext"

# expressions
require_relative "or_tools/comparison"
require_relative "or_tools/comparison_operators"

# bin packing
require_relative "or_tools/knapsack_solver"

# constraint
require_relative "or_tools/bool_var"
require_relative "or_tools/cp_model"
require_relative "or_tools/cp_solver"
require_relative "or_tools/cp_solver_solution_callback"
require_relative "or_tools/sat_int_var"
require_relative "or_tools/sat_linear_expr"

# linear
require_relative "or_tools/linear_expr"
require_relative "or_tools/constant"
require_relative "or_tools/mp_variable"
require_relative "or_tools/linear_constraint"
require_relative "or_tools/product_cst"
require_relative "or_tools/solver"

# routing
require_relative "or_tools/int_var"
require_relative "or_tools/routing_index_manager"
require_relative "or_tools/routing_model"

# solution printers
require_relative "or_tools/objective_solution_printer"
require_relative "or_tools/var_array_solution_printer"
require_relative "or_tools/var_array_and_objective_solution_printer"

# higher level interfaces
require_relative "or_tools/basic_scheduler"
require_relative "or_tools/seating"
require_relative "or_tools/sudoku"
require_relative "or_tools/tsp"

# modules
require_relative "or_tools/version"

module ORTools
  class Error < StandardError; end
end
