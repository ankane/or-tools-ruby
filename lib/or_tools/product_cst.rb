module ORTools
  class ProductCst < LinearExpr
    attr_reader :expr, :coef

    def initialize(expr, coef)
      @expr = cast_to_lin_exp(expr)
      raise TypeError unless coef.is_a?(Numeric)
      @coef = coef
    end

    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      current_multiplier = multiplier * @coef
      if current_multiplier
        stack << [current_multiplier, @expr]
      end
    end

    def cast_to_lin_exp(v)
      v.is_a?(Numeric) ? Constant.new(v) : v
    end
  end
end
