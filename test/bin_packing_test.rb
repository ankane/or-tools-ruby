require_relative "test_helper"

class BinPackingTest < Minitest::Test
  # https://developers.google.com/optimization/bin/knapsack
  def test_knapsack_simple
    values = [
      360, 83, 59, 130, 431, 67, 230, 52, 93, 125, 670, 892, 600, 38, 48, 147,
      78, 256, 63, 17, 120, 164, 432, 35, 92, 110, 22, 42, 50, 323, 514, 28,
      87, 73, 78, 15, 26, 78, 210, 36, 85, 189, 274, 43, 33, 10, 19, 389, 276,
      312
    ]
    weights = [[
      7, 0, 30, 22, 80, 94, 11, 81, 70, 64, 59, 18, 0, 36, 3, 8, 15, 42, 9, 0,
      42, 47, 52, 32, 26, 48, 55, 6, 29, 84, 2, 4, 18, 56, 7, 29, 93, 44, 71,
      3, 86, 66, 31, 65, 0, 79, 20, 65, 52, 13
    ]]
    capacities = [850]

    solver = ORTools::KnapsackSolver.new
    solution = solver.solve(values, weights, capacities)

    assert_equal 7534, solution[:total_value]
    assert_equal 850, solution[:total_weight]
    expected_items = [0, 1, 3, 4, 6, 10, 11, 12, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 29, 30, 31, 32, 34, 38, 39, 41, 42, 44, 47, 48, 49]
    assert_equal expected_items, solution[:packed_items]
    expected_weights = [7, 0, 22, 80, 11, 59, 18, 0, 3, 8, 15, 42, 9, 0, 47, 52, 26, 6, 29, 84, 2, 4, 18, 7, 71, 3, 66, 31, 0, 65, 52, 13]
    assert_equal expected_weights, solution[:packed_weights]
  end

  def test_knapsack_advanced
    values = [
      360, 83, 59, 130, 431, 67, 230, 52, 93, 125, 670, 892, 600, 38, 48, 147,
      78, 256, 63, 17, 120, 164, 432, 35, 92, 110, 22, 42, 50, 323, 514, 28,
      87, 73, 78, 15, 26, 78, 210, 36, 85, 189, 274, 43, 33, 10, 19, 389, 276,
      312
    ]
    weights = [[
      7, 0, 30, 22, 80, 94, 11, 81, 70, 64, 59, 18, 0, 36, 3, 8, 15, 42, 9, 0,
      42, 47, 52, 32, 26, 48, 55, 6, 29, 84, 2, 4, 18, 56, 7, 29, 93, 44, 71,
      3, 86, 66, 31, 65, 0, 79, 20, 65, 52, 13
    ]]
    capacities = [850]

    solver = ORTools::KnapsackSolver.new(:branch_and_bound, "KnapsackExample")
    solver.init(values, weights, capacities)
    computed_value = solver.solve

    packed_items = []
    packed_weights = []
    total_weight = 0
    values.length.times do |i|
      if solver.best_solution_contains?(i)
        packed_items << i
        packed_weights << weights[0][i]
        total_weight += weights[0][i]
      end
    end

    assert_equal 7534, computed_value
    assert_equal 850, total_weight
    expected_items = [0, 1, 3, 4, 6, 10, 11, 12, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 29, 30, 31, 32, 34, 38, 39, 41, 42, 44, 47, 48, 49]
    assert_equal expected_items, packed_items
    expected_weights = [7, 0, 22, 80, 11, 59, 18, 0, 3, 8, 15, 42, 9, 0, 47, 52, 26, 6, 29, 84, 2, 4, 18, 7, 71, 3, 66, 31, 0, 65, 52, 13]
    assert_equal expected_weights, packed_weights
  end
end
