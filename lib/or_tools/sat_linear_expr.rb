module ORTools
  class SatLinearExpr
    attr_reader :vars

    def initialize(vars = [])
      @vars = vars
    end

    def +(other)
      case other
      when SatLinearExpr
        self.class.new(vars + other.vars)
      when BoolVar
        self.class.new(vars + [[other, 1]])
      else
        raise ArgumentError, "Unsupported type"
      end
    end

    def -(other)
      # negate constant terms
      self.class.new(vars + other.vars.map { |a, b| [a, -b] })
    end

    def ==(other)
      Comparison.new(:equal, self, other)
    end

    def <=(other)
      Comparison.new(:less_or_equal, self, other)
    end

    def >(other)
      Comparison.new(:greater_than, self, other)
    end
  end
end
