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

  # https://developers.google.com/optimization/bin/multiple_knapsack
  def test_multiple_knapsack
    data = {}
    weights = [48, 30, 42, 36, 36, 48, 42, 42, 36, 24, 30, 30, 42, 36, 36]
    values = [10, 30, 25, 50, 35, 30, 15, 40, 30, 35, 45, 10, 20, 30, 25]
    data[:weights] = weights
    data[:values] = values
    data[:items] = (0...weights.length).to_a
    data[:num_items] = weights.length
    num_bins = 5
    data[:bins] = (0...num_bins).to_a
    data[:bin_capacities] = [100, 100, 100, 100, 100]

    solver = ORTools::Solver.new("simple_mip_program", :cbc)

    x = {}
    data[:items].each do |i|
      data[:bins].each do |j|
        x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
      end
    end

    data[:items].each do |i|
      sum = ORTools::LinearExpr.new
      data[:bins].each do |j|
        sum += x[[i, j]]
      end
      solver.add(sum <= 1.0)
    end

    data[:bins].each do |j|
      weight = ORTools::LinearExpr.new
      data[:items].each do |i|
        weight += x[[i, j]] * data[:weights][i]
      end
      solver.add(weight <= data[:bin_capacities][j])
    end

    objective = solver.objective

    data[:items].each do |i|
      data[:bins].each do |j|
        objective.set_coefficient(x[[i, j]], data[:values][i])
      end
    end
    objective.set_maximization

    status = solver.solve

    assert_equal :optimal, status
    assert_equal 395, objective.value

    bins = []
    bin_weights = []
    bin_values = []

    total_weight = 0
    data[:bins].each do |j|
      bin_weight = 0
      bin_value = 0
      bin = []
      data[:items].each do |i|
        if x[[i, j]].solution_value > 0
          bin << i
          bin_weight += data[:weights][i]
          bin_value += data[:values][i]
        end
      end
      bins << bin
      bin_weights << bin_weight
      bin_values << bin_value
      total_weight += bin_weight
    end

    assert_equal [[5, 7], [1, 4, 10], [3, 8, 9], [2, 12], [13, 14]], bins
    assert_equal [90, 96, 96, 84, 72], bin_weights
    assert_equal [70, 110, 115, 45, 55], bin_values
    assert_equal 438, total_weight
  end

  # https://developers.google.com/optimization/bin/bin_packing
  def test_bin_packing
    data = {}
    weights = [48, 30, 19, 36, 36, 27, 42, 42, 36, 24, 30]
    data[:weights] = weights
    data[:items] = (0...weights.length).to_a
    data[:bins] = data[:items]
    data[:bin_capacity] = 100

    solver = ORTools::Solver.new("simple_mip_program", :cbc)

    x = {}
    data[:items].each do |i|
      data[:bins].each do |j|
        x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
      end
    end

    y = {}
    data[:bins].each do |j|
      y[j] = solver.int_var(0, 1, "y[%i]" % j)
    end

    data[:items].each do |i|
      solver.add(solver.sum(data[:bins].map { |j| x[[i, j]] }) == 1)
    end

    data[:bins].each do |j|
      sum = solver.sum(data[:items].map { |i| x[[i, j]] * data[:weights][i] })
      solver.add(sum <= y[j] * data[:bin_capacity])
    end

    solver.minimize(solver.sum(data[:bins].map { |j| y[j] }))

    status = solver.solve

    assert_equal :optimal, status

    bins = []
    bin_weights = []

    num_bins = 0
    data[:bins].each do |j|
      if y[j].solution_value == 1
        bin_items = []
        bin_weight = 0
        data[:items].each do |i|
          if x[[i, j]].solution_value > 0
            bin_items << i
            bin_weight += data[:weights][i]
          end
        end
        if bin_weight > 0
          num_bins += 1
          bins << bin_items
          bin_weights << bin_weight
        end
      end
    end

    assert_equal [[1, 5, 10], [0, 6], [2, 4, 7], [3, 8, 9]], bins
    assert_equal [87, 90, 97, 96], bin_weights
    assert_equal 4, num_bins
  end
end
