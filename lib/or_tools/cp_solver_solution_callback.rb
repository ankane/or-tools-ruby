module ORTools
  class CpSolverSolutionCallback
    attr_writer :response

    def value(expr)
      # TODO uncomment in 0.19.0
      # raise "solve() has not been called." unless response?
      case expr
      when SatIntVar
        @response&.solution_integer_value(expr)
      when BoolVar
        @response&.solution_boolean_value(expr)
      else
        raise "Unsupported type: #{expr.class.name}"
      end
    end

    def response?
      !@response.nil?
    end

    def stop_search
      # TODO uncomment in 0.19.0
      # raise "solve() has not been called." unless response?
      @stopped = true
    end

    def objective_value
      # TODO uncomment in 0.19.0
      # raise "solve() has not been called." unless response?
      @response&.objective_value
    end

    def best_objective_bound
      raise "solve() has not been called." unless response?
      @response.best_objective_bound
    end

    def num_booleans
      raise "solve() has not been called." unless response?
      @response.num_booleans
    end

    def num_conflicts
      raise "solve() has not been called." unless response?
      @response.num_conflicts
    end

    def num_branches
      raise "solve() has not been called." unless response?
      @response.num_branches
    end

    def num_integer_propagations
      raise "solve() has not been called." unless response?
      @response.num_integer_propagations
    end

    def num_binary_propagations
      raise "solve() has not been called." unless response?
      @response.num_binary_propagations
    end

    def deterministic_time
      raise "solve() has not been called." unless response?
      @response.deterministic_time
    end

    def wall_time
      raise "solve() has not been called." unless response?
      @response.wall_time
    end

    def user_time
      raise "solve() has not been called." unless response?
      @response.user_time
    end
  end
end
