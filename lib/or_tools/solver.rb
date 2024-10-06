module ORTools
  class Solver
    def sum(arr)
      LinearExpr.new(arr)
    end

    def add(expr)
      coeffs, lb, ub = expr.extract

      constraint = self.constraint(lb || -infinity, ub || infinity)
      coeffs.each do |v, c|
        constraint.set_coefficient(v, c.to_f)
      end
      constraint
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
      coeffs = expr.coeffs
      offset = coeffs.delete(OFFSET_KEY)

      objective.clear
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
