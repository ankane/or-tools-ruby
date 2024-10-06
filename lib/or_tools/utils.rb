module ORTools
  module Utils
    def self.index_constraint(constraint)
      raise ArgumentError, "Expected Comparison" unless constraint.is_a?(Comparison)

      left = index_expression(constraint.left, check_linear: true)
      right = index_expression(constraint.right, check_linear: true)

      const = right.delete(nil).to_f - left.delete(nil).to_f
      right.each do |k, v|
        left[k] -= v
      end

      [left, constraint.op, const]
    end

    def self.index_expression(expression, check_linear: false)
      vars = Hash.new(0)
      case expression
      when Numeric
        vars[nil] += expression
      when Constant
        vars[nil] += expression.value
      when Variable
        vars[expression] += 1
      when Product
        if check_linear && expression.left.vars.any? && expression.right.vars.any?
          raise ArgumentError, "Nonlinear"
        end
        vars = index_product(expression.left, expression.right)
      when Expression
        expression.parts.each do |part|
          index_expression(part, check_linear: check_linear).each do |k, v|
            vars[k] += v
          end
        end
      else
        raise TypeError, "Unsupported type"
      end
      vars
    end

    def self.index_product(left, right)
      # normalize
      types = [Constant, Variable, Product, Expression]
      if types.index { |t| left.is_a?(t) } > types.index { |t| right.is_a?(t) }
        left, right = right, left
      end

      vars = Hash.new(0)
      case left
      when Constant
        vars = index_expression(right)
        vars.transform_values! { |v| v * left.value }
      when Variable
        case right
        when Variable
          vars[quad_key(left, right)] = 1
        when Product
          index_expression(right).each do |k, v|
            case k
            when Array
              raise Error, "Non-quadratic"
            when Variable
              vars[quad_key(left, k)] = v
            else # nil
              raise "Bug?"
            end
          end
        else
          right.parts.each do |part|
            index_product(left, part).each do |k, v|
              vars[k] += v
            end
          end
        end
      when Product
        index_expression(left).each do |lk, lv|
          index_expression(right).each do |rk, rv|
            if lk.is_a?(Variable) && rk.is_a?(Variable)
              vars[quad_key(lk, rk)] = lv * rv
            else
              raise "todo"
            end
          end
        end
      else # Expression
        left.parts.each do |lp|
          right.parts.each do |rp|
            index_product(lp, rp).each do |k, v|
              vars[k] += v
            end
          end
        end
      end
      vars
    end

    def self.quad_key(left, right)
      if left.object_id <= right.object_id
        [left, right]
      else
        [right, left]
      end
    end
  end
end
