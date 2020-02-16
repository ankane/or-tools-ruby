module ORTools
  class SatLinearExpr
    attr_reader :vars

    def initialize(vars)
      @vars = vars
    end

    def +(other)
      self.class.new(vars + other.vars)
    end

    def -(other)
      # negate constant terms
      self.class.new(vars + other.vars.map { |a, b| [a, -b] })
    end

    def <=(other)
      Comparison.new(:less_or_equal, self, other)
    end
  end
end
