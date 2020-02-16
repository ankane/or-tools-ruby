module ORTools
  class SatLinearExpr
    include ComparisonOperators

    attr_reader :vars

    def initialize(vars = [])
      @vars = vars
    end

    def +(other)
      add(other, 1)
    end

    def -(other)
      add(other, -1)
    end

    private

    def add(other, sign)
      other_vars =
        case other
        when SatLinearExpr
          other.vars
        when BoolVar
          [[other, 1]]
        else
          raise ArgumentError, "Unsupported type"
        end

      self.class.new(vars + other_vars.map { |a, b| [a, sign * b] })
    end
  end
end
