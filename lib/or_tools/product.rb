module ORTools
  class Product < Expression
    attr_reader :left, :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def inspect
      if @left.is_a?(Constant) && @right.is_a?(Variable) && left.value == -1
         "-#{inspect_part(@right)}"
      else
        "#{inspect_part(@left)} * #{inspect_part(@right)}"
      end
    end

    def value
      return nil if left.value.nil? || right.value.nil?

      left.value * right.value
    end

    def vars
      @vars ||= (@left.vars + @right.vars).uniq
    end

    private

    def inspect_part(var)
      if var.instance_of?(Expression)
        "(#{var.inspect})"
      else
        var.inspect
      end
    end
  end
end
