module ORTools
  module Variable
    include ExpressionMethods

    def inspect
      name
    end

    def vars
      @vars ||= [self]
    end
  end

  class MPVariable
    include Variable
  end

  class SatIntVar
    include Variable
  end

  class BoolVar
    include Variable
  end

  class IntVar
    include Variable
  end
end
