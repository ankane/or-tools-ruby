module ORTools
  class SumArray < LinearExpr
    attr_reader :array

    def initialize(array)
      @array = array.map { |v| cast_to_lin_exp(v) }
    end

    def add_self_to_coeff_map_or_stack(coeffs, multiplier, stack)
      @array.reverse.each do |arg|
        stack << [multiplier, arg]
      end
    end

    def cast_to_lin_exp(v)
      v.is_a?(Numeric) ? Constant.new(v) : v
    end

    def to_s
      "#{@array.map(&:to_s).reject { |v| v == "0" }.join(" + ")}"
    end
  end
end
