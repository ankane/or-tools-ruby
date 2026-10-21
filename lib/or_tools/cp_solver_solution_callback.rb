module ORTools
  class CpSolverSolutionCallback
    attr_writer :response

    def value(expr)
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

    def objective_value
      # TODO check response? in 0.19.0
      @response&.objective_value
    end

    def best_objective_bound
      unless response?
        raise "solve() has not been called."
      end
      @response.best_objective_bound
    end

    def stop_search
      # TODO check response? in 0.19.0
      @stopped = true
    end
  end
end
