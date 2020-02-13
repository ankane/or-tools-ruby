module ORTools
  class KnapsackSolver
    def self.new(*args)
      args = [:branch_and_bound, "KnapsackExample"] if args.empty?
      super(*args)
    end

    def solve(*args)
      return _solve if args.empty?

      values, weights, capacities = *args
      init(values, weights, capacities)
      computed_value = _solve

      packed_items = []
      packed_weights = []
      total_weight = 0
      values.length.times do |i|
        if best_solution_contains?(i)
          packed_items << i
          packed_weights << weights[0][i]
          total_weight += weights[0][i]
        end
      end

      {
        total_value: computed_value,
        total_weight: total_weight,
        packed_items: packed_items,
        packed_weights: packed_weights
      }
    end
  end
end
