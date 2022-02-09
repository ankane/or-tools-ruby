module ORTools
  class LinearConstraint
    attr_reader :expr, :lb, :ub

    def initialize(expr, lb, ub)
      @expr = expr
      @lb = lb
      @ub = ub
    end

    def extract(solver)
      coeffs = @expr.coeffs
      constant = coeffs.delete(OFFSET_KEY) || 0.0
      lb = -solver.infinity
      ub = solver.infinity
      if @lb > -Float::INFINITY
        lb = @lb - constant
      end
      if @ub < Float::INFINITY
        ub = @ub - constant
      end

      constraint = solver.constraint(lb, ub)
      coeffs.each do |v, c|
        constraint.set_coefficient(v, c.to_f)
      end
      constraint
    end
  end
end
