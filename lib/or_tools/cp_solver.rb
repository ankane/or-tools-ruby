require "forwardable"

module ORTools
  class CpSolver
    extend Forwardable

    def_delegators :@response, :objective_value, :num_conflicts, :num_branches, :wall_time

    def solve(model, observer = nil)
      @response = _solve(model, parameters, observer)
      observer.response = @response if observer
      @response.status
    end

    def value(var)
      # could also check solution_size == 0
      unless [:feasible, :optimal].include?(@response.status)
        # could return nil, but raise error like Python library
        raise Error, "No solution found"
      end

      if var.is_a?(BoolVar)
        _solution_boolean_value(@response, var)
      else
        _solution_integer_value(@response, var)
      end
    end

    def solution_info
      @response.solution_info
    end

    def sufficient_assumptions_for_infeasibility
      @response.sufficient_assumptions_for_infeasibility
    end

    def parameters
      @parameters ||= SatParameters.new
    end
  end
end
