module ORTools
  class CpModel
    def add(comparison)
      method_name =
        case comparison.operator
        when "=="
          :add_equality
        when "!="
          :add_not_equal
        when ">"
          :add_greater_than
        when ">="
          :add_greater_or_equal
        when "<"
          :add_less_than
        when "<="
          :add_less_or_equal
        else
          raise ArgumentError, "Unknown operator: #{comparison.operator}"
        end

      send(method_name, comparison.left, comparison.right)
    end

    def sum(arr)
      arr.sum(SatLinearExpr.new)
    end

    def inspect
      to_s
    end
  end
end
