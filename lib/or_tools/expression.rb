module ORTools
  module ExpressionMethods
    attr_reader :parts

    def +(other)
      Expression.new((parts || [self]) + [Expression.to_expression(other)])
    end

    def -(other)
      Expression.new((parts || [self]) + [-Expression.to_expression(other)])
    end

    def -@
      -1 * self
    end

    def *(other)
      Expression.new([Product.new(self, Expression.to_expression(other))])
    end

    def >(other)
      Comparison.new(self, :>, other)
    end

    def <(other)
      Comparison.new(self, :<, other)
    end

    def >=(other)
      Comparison.new(self, :>=, other)
    end

    def <=(other)
      Comparison.new(self, :<=, other)
    end

    def ==(other)
      Comparison.new(self, :==, other)
    end

    def !=(other)
      Comparison.new(self, :!=, other)
    end

    def inspect
      @parts.reject { |v| v.is_a?(Constant) && v.value == 0 }.map(&:inspect).join(" + ").gsub(" + -", " - ")
    end

    def to_s
      inspect
    end

    # keep order
    def coerce(other)
      if other.is_a?(Numeric)
        [Constant.new(other), self]
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end

    def vars
      @vars ||= @parts.flat_map(&:vars)
    end
  end

  class Expression
    include ExpressionMethods

    def initialize(parts = [])
      @parts = parts
    end

    # private
    def self.to_expression(other)
      if other.is_a?(Numeric)
        Constant.new(other)
      elsif other.is_a?(Variable) || other.is_a?(Expression)
        other
      else
        raise TypeError, "can't cast #{other.class.name} to Expression"
      end
    end
  end
end
