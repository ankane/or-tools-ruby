module ORTools
  class Constant < LinearExpr
    def initialize(val)
      @val = val
    end

    def to_s
      @val.to_s
    end

    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      coeffs[OFFSET_KEY] += @val * multiplier
    end
  end

  class FakeMPVariableRepresentingTheConstantOffset
    def solution_value
      1
    end
  end

  OFFSET_KEY = FakeMPVariableRepresentingTheConstantOffset.new
end
