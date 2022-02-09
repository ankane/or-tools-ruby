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

    def to_s
      name
    end

    # TODO add class
    def inspect
      to_s
    end
  end
end
