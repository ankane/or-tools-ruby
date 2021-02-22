module ORTools
  class SatIntVar
    include ComparisonOperators

    def *(other)
      SatLinearExpr.new([[self, other]])
    end

    def +(other)
      SatLinearExpr.new([[self, 1], [other, 1]])
    end

    def -(other)
      SatLinearExpr.new([[self, 1], [-other, 1]])
    end

    def -@
      SatLinearExpr.new([[self, -1]])
    end

    # for now
    def inspect
      name
    end
  end
end
