module ORTools
  class CpSolverSolutionCallback
    attr_writer :response

    def value(expr)
      @response.solution_boolean_value(expr)
    end
  end
end
