module ORTools
  class Solver
    def sum(arr)
      arr.sum(LinearExpr.new)
    end
  end
end
