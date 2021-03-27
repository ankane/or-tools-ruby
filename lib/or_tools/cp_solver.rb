require "forwardable"

module ORTools
  class CpSolver
    extend Forwardable

    def_delegators :@response, :objective_value, :num_conflicts, :num_branches, :wall_time

    def solve(model)
      @response = _solve(model, parameters)
      @response.status
    end

    def value(var)
      if var.is_a?(BoolVar)
        _solution_boolean_value(@response, var)
      else
        _solution_integer_value(@response, var)
      end
    end

    def solve_with_solution_callback(model, observer)
      @response = _solve_with_observer(model, parameters, observer, false)
      @response.status
    end

    def search_for_all_solutions(model, observer)
      @response = _solve_with_observer(model, parameters, observer, true)
      @response.status
    end

    def sufficient_assumptions_for_infeasibility
      @response.sufficient_assumptions_for_infeasibility
    end

    def parameters
      @parameters ||= SatParameters.new
    end
  end
end
