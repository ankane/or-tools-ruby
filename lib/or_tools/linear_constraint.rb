module ORTools
  class LinearConstraint
    attr_reader :expr, :lb, :ub

    def initialize(expr, lb, ub)
      @expr = expr
      @lb = lb
      @ub = ub
    end

    def to_s
      if @lb > -Float::INFINITY && @ub < Float::INFINITY
        if @lb == @ub
          "#{@expr} == #{@lb}"
        else
          "#{@lb} <= #{@expr} <= #{@ub}"
        end
      elsif @lb > -Float::INFINITY
        "#{@expr} >= #{@lb}"
      elsif @ub < Float::INFINITY
        "#{@expr} <= #{@ub}"
      else
        "Trivial inequality (always true)"
      end
    end

    def inspect
      "#<#{self.class.name} #{to_s}>"
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
