module ORTools
  class SatIntVar
    def *(other)
      SatLinearExpr.new([[self, other]])
    end

    def !=(other)
      Comparison.new(:not_equal, self, other)
    end
  end
end
