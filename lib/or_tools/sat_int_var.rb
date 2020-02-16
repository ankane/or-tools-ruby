module ORTools
  class SatIntVar
    include ComparisonOperators

    def *(other)
      SatLinearExpr.new([[self, other]])
    end
  end
end
