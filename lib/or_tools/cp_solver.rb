require "forwardable"

module ORTools
  class CpSolver
    extend Forwardable

    def_delegators :@response, :objective_value, :num_conflicts, :num_branches, :wall_time

    def solve(model, observer = nil)
      @response = _solve(model, parameters, observer)
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

    def solve_with_solution_callback(model, observer)
      warn "[or-tools] solve_with_solution_callback is deprecated; use solve(model, callback)"
      solve(model, observer)
    end

    def search_for_all_solutions(model, observer)
      warn "[or-tools] search_for_all_solutions is deprecated; use solve() with solver.parameters.enumerate_all_solutions = true"
      previous_value = parameters.enumerate_all_solutions
      begin
        parameters.enumerate_all_solutions = true
        solve(model, observer)
      ensure
        parameters.enumerate_all_solutions = previous_value
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
