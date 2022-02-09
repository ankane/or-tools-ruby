module ORTools
  class Comparison
    attr_reader :operator, :left, :right

    def initialize(operator, left, right)
      @operator = operator
      @left = left
      @right = right
    end

    def to_s
      "#{left.inspect} #{operator} #{right.inspect}"
    end

    # TODO add class
    def inspect
      to_s
    end
  end
end
