module ORTools
  class LinearExpr
    def +(other)
      if other.is_a?(LinearExpr)
        _add_linear_expr(other)
      else
        _add_mp_variable(other)
      end
    end

    def >=(other)
      if other.is_a?(LinearExpr)
        _gte_linear_expr(other)
      else
        _gte_double(other)
      end
    end

    def <=(other)
      if other.is_a?(LinearExpr)
        _lte_linear_expr(other)
      else
        _lte_double(other)
      end
    end
  end
end
