module ORTools
  class CpSolverSolutionCallback
    attr_writer :response

    def value(expr)
      case expr
      when SatIntVar
        @response.solution_integer_value(expr)
      when BoolVar
        @response.solution_boolean_value(expr)
      else
        raise "Unsupported type: #{expr.class.name}"
      end
    end

    def objective_value
      @response.objective_value
    end
  end
end
