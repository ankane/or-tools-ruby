module ORTools
  class Comparison
    attr_reader :operator, :left, :right

    def initialize(operator, left, right)
      @operator = operator
      @left = left
      @right = right
    end

    def to_s
      "#{left} #{operator} #{right}"
    end

    def inspect
      "#<#{self.class.name} #{to_s}>"
    end
  end
end
