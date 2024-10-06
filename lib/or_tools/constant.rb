module ORTools
  class Constant < Expression
    attr_reader :value

    def initialize(value)
      @value = value
    end

    # simplify Ruby sum
    def +(other)
      @value == 0 ? other : super
    end

    def inspect
      @value.to_s
    end

    def -@
      Constant.new(-value)
    end

    def vars
      @vars ||= []
    end
  end
end
