module ORTools
  class CpModel
    def add(comparison)
      case comparison.operator
      when :equal
        add_equal(comparison.left, comparison.right)
      when :not_equal
        add_not_equal(comparison.left, comparison.right)
      when :greater_than
        add_greater_than(comparison.left, comparison.right)
      when :less_or_equal
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
