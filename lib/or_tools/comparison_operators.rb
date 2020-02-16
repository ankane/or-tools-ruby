module ORTools
  module ComparisonOperators
    ["==", "!=", ">", ">=", "<", "<="].each do |operator|
      define_method(operator) do |other|
        Comparison.new(operator, self, other)
      end
    end
  end
end
