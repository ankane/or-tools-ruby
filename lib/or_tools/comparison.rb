module ORTools
  class Comparison
    attr_reader :operator, :left, :right

    def initialize(operator, left, right)
      @operator = operator
      @left = left
      @right = right
    end

    def inspect
      "#{left.inspect} #{operator} #{right.inspect}"
    end
  end
end
