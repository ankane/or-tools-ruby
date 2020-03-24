module ORTools
  class BoolVar
    include ComparisonOperators

    def *(other)
      SatLinearExpr.new([[self, other]])
    end
  end
end
