module ORTools
  class SatLinearExpr
    include ComparisonOperators

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
  end
end
