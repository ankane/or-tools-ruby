module ORTools
  module MathOpt
    class Model
      def add_linear_constraint(expr)
        left, op, const = Utils.index_constraint(expr)

        constraint = _add_linear_constraint
        left.each do |var, c|
          _set_coefficient(constraint, var, c)
        end
        case op
        when :<=
          _set_upper_bound(constraint, const)
        when :>=
          _set_lower_bound(constraint, const)
        when :==
          _set_lower_bound(constraint, const)
          _set_upper_bound(constraint, const)
        else
          raise ArgumentError, "Supported operations are ==, <=, and >="
        end
        nil
      end

      def maximize(objective)
        set_objective(objective)
        _set_maximize
      end

      def minimize(objective)
        set_objective(objective)
        _set_minimize
      end

      # TODO change default for MIP
      def solve(solver_type = :glop)
        _solve(solver_type)
      end

      private

      def set_objective(objective)
        objective = Expression.to_expression(objective)
        coeffs = Utils.index_expression(objective, check_linear: true)
        offset = coeffs.delete(nil)

        objective.set_offset(offset) if offset
        coeffs.each do |var, c|
          _set_objective_coefficient(var, c)
        end
      end
    end
  end
end
