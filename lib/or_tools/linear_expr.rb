module ORTools
  module LinearExprMethods
    def solution_value
      coeffs.sum { |var, coeff| var.solution_value * coeff }
    end

    def coeffs
      coeffs = Hash.new(0.0)
      stack = [[1.0, self]]
      while stack.any?
        current_multiplier, current_expression = stack.pop

        current_expression.add_self_to_coeff_map_or_stack(coeffs, current_multiplier, stack)
      end
      coeffs
    end

    def +(expr)
      LinearExpr.new([self, expr])
    end

    def -(expr)
      LinearExpr.new([self, -expr])
    end

    def *(other)
      if is_a?(Constant)
        ProductCst.new(other, @val)
      else
        ProductCst.new(self, other)
      end
    end

    def /(cst)
      ProductCst.new(self, 1.0 / other)
    end

    def -@
      ProductCst.new(self, -1)
    end

    def ==(arg)
      if arg.is_a?(Numeric)
        LinearConstraint.new(self, arg, arg)
      else
        LinearConstraint.new(self - arg, 0.0, 0.0)
      end
    end

    def >=(arg)
      if arg.is_a?(Numeric)
        LinearConstraint.new(self, arg, Float::INFINITY)
      else
        LinearConstraint.new(self - arg, 0.0, Float::INFINITY)
      end
    end

    def <=(arg)
      if arg.is_a?(Numeric)
        LinearConstraint.new(self, -Float::INFINITY, arg)
      else
        LinearConstraint.new(self - arg, -Float::INFINITY, 0.0)
      end
    end

    def inspect
      "#<#{self.class.name} #{to_s}>"
    end

    def coerce(other)
      if other.is_a?(Numeric)
        [Constant.new(other), self]
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end
  end

  class LinearExpr
    include LinearExprMethods

    attr_reader :array

    def initialize(array = [])
      @array = array.map { |v| cast_to_lin_exp(v) }
    end

    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      @array.reverse_each do |arg|
        stack << [multiplier, arg]
      end
    end

    def cast_to_lin_exp(v)
      v.is_a?(Numeric) ? Constant.new(v) : v
    end

    def to_s
      if @array.empty?
        "(empty)"
      else
        "#{@array.map(&:to_s).reject { |v| v == "0" }.join(" + ")}".gsub(" + -", " - ")
      end
    end
  end

  SumArray = LinearExpr
end
