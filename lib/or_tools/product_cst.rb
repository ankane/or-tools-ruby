module ORTools
  class ProductCst < LinearExpr
    attr_reader :expr, :coef

    def initialize(expr, coef)
      @expr = cast_to_lin_exp(expr)
      # TODO improve message
      raise TypeError, "expected numeric" unless coef.is_a?(Numeric)
      @coef = coef
    end

    def to_s
      if @coef == -1
        "-#{@expr}"
      else
        expr = @expr.to_s
        if expr.include?("+") || expr.include?("-")
          expr = "(#{expr})"
        end
        "#{@coef} * #{expr}"
      end
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
