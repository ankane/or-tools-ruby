# ext
require "or_tools/ext"

# expressions
require_relative "or_tools/expression"
require_relative "or_tools/comparison"
require_relative "or_tools/constant"
require_relative "or_tools/product"
require_relative "or_tools/variable"

# bin packing
require_relative "or_tools/knapsack_solver"

# constraint
require_relative "or_tools/cp_model"
require_relative "or_tools/cp_solver"
require_relative "or_tools/cp_solver_solution_callback"
require_relative "or_tools/objective_solution_printer"
require_relative "or_tools/var_array_solution_printer"
require_relative "or_tools/var_array_and_objective_solution_printer"

# linear
require_relative "or_tools/solver"

# math opt
require_relative "or_tools/math_opt/model"
require_relative "or_tools/math_opt/variable"

# routing
require_relative "or_tools/routing_index_manager"
require_relative "or_tools/routing_model"

# higher level interfaces
require_relative "or_tools/basic_scheduler"
require_relative "or_tools/seating"
require_relative "or_tools/sudoku"
require_relative "or_tools/tsp"

# modules
require_relative "or_tools/utils"
require_relative "or_tools/version"

module ORTools
  class Error < StandardError; end
end
