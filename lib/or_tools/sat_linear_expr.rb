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

    def *(other)
      if vars.size == 1
        self.class.new([[vars[0][0], vars[0][1] * other]])
      else
        raise ArgumentError, "Multiplication not allowed here"
      end
    end

    def inspect
      vars.map do |v|
        k = v[0]
        k = k.respond_to?(:name) ? k.name : k.inspect
        if v[1] == 1
          k
        else
          "#{k} * #{v[1]}"
        end
      end.join(" + ").sub(" + -", " - ")
    end

    private

    def add(other, sign)
      other_vars =
        case other
        when SatLinearExpr
          other.vars
        when BoolVar, SatIntVar, Integer
          [[other, 1]]
        else
          raise ArgumentError, "Unsupported type: #{other.class.name}"
        end

      self.class.new(vars + other_vars.map { |a, b| [a, sign * b] })
    end
  end
end
