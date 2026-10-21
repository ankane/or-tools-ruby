module ORTools
  class CpSolver
    def parameters
      @parameters ||= SatParameters.new
    end

    def solve(model, observer = nil)
      @response = _solve(model, parameters, observer)
      observer.response = @response if observer
      @response.status
    end

    def value(var)
      response = checked_response

      # could also check solution_size == 0
      unless [:feasible, :optimal].include?(response.status)
        # could return nil, but raise error like Python library
        raise Error, "No solution found"
      end

      if var.is_a?(BoolVar)
        _solution_boolean_value(response, var)
      else
        _solution_integer_value(response, var)
      end
    end

    def objective_value
      checked_response.objective_value
    end

    def best_objective_bound
      checked_response.best_objective_bound
    end

    def num_booleans
      checked_response.num_booleans
    end

    def num_conflicts
      checked_response.num_conflicts
    end

    def num_branches
      checked_response.num_branches
    end

    def num_binary_propagations
      checked_response.num_binary_propagations
    end

    def num_integer_propagations
      checked_response.num_integer_propagations
    end

    def deterministic_time
      checked_response.deterministic_time
    end

    def wall_time
      checked_response.wall_time
    end

    def user_time
      checked_response.user_time
    end

    def solve_log
      checked_response.solve_log
    end

    def sufficient_assumptions_for_infeasibility
      checked_response.sufficient_assumptions_for_infeasibility
    end

    def solution_info
      checked_response.solution_info
    end

    private

    def checked_response
      raise "solve() has not been called." if @response.nil?
      @response
    end
  end
end
