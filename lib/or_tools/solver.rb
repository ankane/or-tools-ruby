module ORTools
  class Solver
    def sum(arr)
      Expression.new(arr)
    end

    def add(expr)
      left, op, const = Utils.index_constraint(expr)

      case op
      when :<=
        lb = -infinity
        ub = const
      when :>=
        lb = const
        ub = infinity
      when :==
        lb = const
        ub = const
      else
        raise "todo: #{op}"
      end

      constraint = constraint(lb, ub)
      left.each do |var, c|
        constraint.set_coefficient(var, c)
      end
      nil
    end

    def maximize(expr)
      set_objective(expr)
      objective.set_maximization
    end

    def minimize(expr)
      set_objective(expr)
      objective.set_minimization
    end

    private

    def set_objective(expr)
      coeffs = Utils.index_expression(expr, check_linear: true)
      offset = coeffs.delete(nil)

      objective.clear
      objective.set_offset(offset) if offset
      coeffs.each do |var, c|
        objective.set_coefficient(var, c)
      end
    end

    def self.new(solver_id, *args)
      if args.empty?
        _create(solver_id)
      else
        _new(solver_id, *args)
      end
    end
  end
end
