module ORTools
  class Solver
    def sum(arr)
      SumArray.new(arr)
    end

    def add(expr)
      expr.extract(self)
    end

    def maximize(expr)
      set_objective(expr)
      objective.set_maximization
    end

    def minimize(expr)
      set_objective(expr)
      objective.set_minimization
    end

    private

    def set_objective(expr)
      objective.clear
      coeffs = expr.coeffs
      offset = coeffs.delete(OFFSET_KEY)
      objective.set_offset(offset) if offset
      coeffs.each do |v, c|
        objective.set_coefficient(v, c)
      end
    end

    def self.new(solver_id, *args)
      if args.empty?
        _create(solver_id)
      else
        _new(solver_id, *args)
      end
    end
  end
end
