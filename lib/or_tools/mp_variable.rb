module ORTools
  class MPVariable
    include LinearExprMethods

    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      coeffs[self] += multiplier
    end

    def to_s
      name
    end
  end
end
