require_relative "test_helper"

class NetworkFlowsTest < Minitest::Test
  # https://developers.google.com/optimization/flow/maxflow
  def test_max_flow
    start_nodes = [0, 0, 0, 1, 1, 2, 2, 3, 3]
    end_nodes = [1, 2, 3, 2, 4, 3, 4, 2, 4]
    capacities = [20, 30, 10, 40, 30, 10, 20, 5, 20]

    max_flow = ORTools::SimpleMaxFlow.new

    start_nodes.length.times do |i|
      max_flow.add_arc_with_capacity(start_nodes[i], end_nodes[i], capacities[i])
    end

    assert_equal :optimal, max_flow.solve(0, 4)
    assert_equal 60, max_flow.optimal_flow
    assert_equal 9, max_flow.num_arcs

    arcs = max_flow.num_arcs.times
    assert_equal [0, 0, 0, 1, 1, 2, 2, 3, 3], arcs.map { |i| max_flow.tail(i) }
    assert_equal [1, 2, 3, 2, 4, 3, 4, 2, 4], arcs.map { |i| max_flow.head(i) }
    assert_equal [20, 30, 10, 0, 20, 10, 20, 0, 20], arcs.map { |i| max_flow.flow(i) }
    assert_equal [20, 30, 10, 40, 30, 10, 20, 5, 20], arcs.map { |i| max_flow.capacity(i) }

    assert_equal [0], max_flow.source_side_min_cut
    assert_equal [4, 1], max_flow.sink_side_min_cut
  end

  # https://developers.google.com/optimization/flow/mincostflow
  def test_min_cost_flow
    start_nodes = [ 0, 0,  1, 1,  1,  2, 2,  3, 4]
    end_nodes   = [ 1, 2,  2, 3,  4,  3, 4,  4, 2]
    capacities  = [15, 8, 20, 4, 10, 15, 4, 20, 5]
    unit_costs  = [ 4, 4,  2, 2,  6,  1, 3,  2, 3]
    supplies = [20, 0, 0, -5, -15]

    min_cost_flow = ORTools::SimpleMinCostFlow.new

    start_nodes.length.times do |i|
      min_cost_flow.add_arc_with_capacity_and_unit_cost(
        start_nodes[i], end_nodes[i], capacities[i], unit_costs[i]
      )
    end

    supplies.length.times do |i|
      min_cost_flow.set_node_supply(i, supplies[i])
    end

    assert_equal :optimal, min_cost_flow.solve
    assert_equal 150, min_cost_flow.optimal_cost
    assert_equal 9, min_cost_flow.num_arcs

    arcs = min_cost_flow.num_arcs.times
    assert_equal [0, 0, 1, 1, 1, 2, 2, 3, 4], arcs.map { |i| min_cost_flow.tail(i) }
    assert_equal [1, 2, 2, 3, 4, 3, 4, 4, 2], arcs.map { |i| min_cost_flow.head(i) }
    assert_equal [12, 8, 8, 4, 0, 12, 4, 11, 0], arcs.map { |i| min_cost_flow.flow(i) }
    assert_equal [15, 8, 20, 4, 10, 15, 4, 20, 5], arcs.map { |i| min_cost_flow.capacity(i) }
    assert_equal [48, 32, 16, 8, 0, 12, 12, 22, 0], arcs.map { |i| min_cost_flow.flow(i) * min_cost_flow.unit_cost(i) }
  end

  # https://developers.google.com/optimization/flow/assignment_min_cost_flow
  def test_assignment_min_cost_flow
    min_cost_flow = ORTools::SimpleMinCostFlow.new

    start_nodes = [0, 0, 0, 0] + [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4] + [5, 6, 7, 8]
    end_nodes =   [1, 2, 3, 4] + [5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8] + [9, 9, 9, 9]
    capacities =  [1, 1, 1, 1] + [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] + [1, 1, 1, 1]
    costs  = [0, 0, 0, 0] + [90, 76, 75, 70, 35, 85, 55, 65, 125, 95, 90, 105, 45, 110, 95, 115] + [0, 0, 0, 0]
    supplies = [4, 0, 0, 0, 0, 0, 0, 0, 0, -4]
    source = 0
    sink = 9
    # tasks = 4

    start_nodes.length.times do |i|
      min_cost_flow.add_arc_with_capacity_and_unit_cost(
        start_nodes[i], end_nodes[i], capacities[i], costs[i]
      )
    end

    supplies.length.times do |i|
      min_cost_flow.set_node_supply(i, supplies[i])
    end

    assert_equal :optimal, min_cost_flow.solve
    assert_equal 265, min_cost_flow.optimal_cost

    arcs = min_cost_flow.num_arcs.times.to_a
    arcs.select! { |arc| min_cost_flow.tail(arc) != source && min_cost_flow.head(arc) != sink }
    arcs.select! { |arc| min_cost_flow.flow(arc) > 0 }

    assert_equal [1, 2, 3, 4], arcs.map { |i| min_cost_flow.tail(i) }
    assert_equal [8, 7, 6, 5], arcs.map { |i| min_cost_flow.head(i) }
    assert_equal [70, 55, 95, 45], arcs.map { |i| min_cost_flow.unit_cost(i) }
  end
end
