module ORTools
  class Solver
    def sum(arr)
      SumArray.new(arr)
    end

    def add(expr)
      expr.extract(self)
    end

    def maximize(expr)
      expr.coeffs.each do |v, c|
        objective.set_coefficient(v, c)
      end
      objective.set_maximization
    end

    def minimize(expr)
      expr.coeffs.each do |v, c|
        objective.set_coefficient(v, c)
      end
      objective.set_minimization
    end
  end
end
