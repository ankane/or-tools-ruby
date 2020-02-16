module ORTools
  class CpModel
    def add(comparison)
      case comparison.operator
      when :not_equal
        add_not_equal(comparison.left, comparison.right)
      else
        raise ArgumentError, "Unknown operator: #{comparison.operator}"
      end
    end
  end
end
