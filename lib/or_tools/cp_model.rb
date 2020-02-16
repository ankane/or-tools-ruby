module ORTools
  class CpModel
    def add(comparison)
      case comparison.operator
      when "=="
        add_equality(comparison.left, comparison.right)
      when "!="
        add_not_equal(comparison.left, comparison.right)
      when ">"
        add_greater_than(comparison.left, comparison.right)
      when ">="
        add_greater_or_equal(comparison.left, comparison.right)
      when "<"
        add_less_than(comparison.left, comparison.right)
      when "<="
        add_less_or_equal(comparison.left, comparison.right)
      else
        raise ArgumentError, "Unknown operator: #{comparison.operator}"
      end
    end

    def sum(arr)
      arr.sum(SatLinearExpr.new)
    end
  end
end
