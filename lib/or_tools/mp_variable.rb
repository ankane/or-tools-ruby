module ORTools
  # TODO change to Variable in 0.7.0
  class MPVariable < LinearExpr
    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      coeffs[self] += multiplier
    end

    def to_s
      name
    end

    def inspect
      "#<ORTools::MPVariable @name=\"" + name + "\">";
    end
  end
end
