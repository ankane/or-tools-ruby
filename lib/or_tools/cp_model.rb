module ORTools
  class CpModel
    def add(comparison)
      case comparison
      when Comparison
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
      when true
        add_bool_or([true_var])
      when false
        add_bool_or([])
      else
        raise TypeError, "Not supported: CpModel#add(#{comparison})"
      end
    end

    def sum(arr)
      arr.sum(SatLinearExpr.new)
    end

    def inspect
      to_s
    end
  end
end
