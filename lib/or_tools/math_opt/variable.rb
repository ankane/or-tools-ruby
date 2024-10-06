module ORTools
  module MathOpt
    class Variable
      include ORTools::Variable

      def eql?(other)
        other.is_a?(self.class) && _eql?(other)
      end

      def hash
        id.hash
      end
    end
  end
end
