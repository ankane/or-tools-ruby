module ORTools
  class RoutingSolver
    def add(comparison)
      case comparison
      when Comparison
        add_constraint(_make_constraint(comparison.left, comparison.right, comparison.op))
      when Constraint
        add_constraint(comparison)
      else
        raise TypeError, "Not supported: RoutingSolver#add(#{comparison})"
      end
    end
  end
end
