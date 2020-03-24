require "forwardable"

module ORTools
  class CpSolver
    extend Forwardable

    def_delegators :@response, :objective_value, :num_conflicts, :num_branches, :wall_time

    def solve(model)
      @response = _solve(model)
      @response.status
    end

    def value(var)
      _solution_integer_value(@response, var)
    end

    def solve_with_solution_callback(model, observer)
      @response = _solve_with_observer(model, observer, false)
      @response.status
    end

    def search_for_all_solutions(model, observer)
      @response = _solve_with_observer(model, observer, true)
      @response.status
    end
  end
end
