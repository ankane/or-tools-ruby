module ORTools
  class SatIntVar
    def !=(other)
      Comparison.new(:not_equal, self, other)
    end
  end
end
