module ORTools
  class CpSolver
    def solve(model)
      @response = _solve(model)
      @response.status
    end

    def value(var)
      _solution_integer_value(@response, var)
    end
  end
end
