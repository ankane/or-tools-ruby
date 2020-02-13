require_relative "test_helper"

class AssignmentTest < Minitest::Test
  # https://developers.google.com/optimization/assignment/simple_assignment
  def test_assignment
    cost = [[ 90,  76, 75,  70],
            [ 35,  85, 55,  65],
            [125,  95, 90, 105],
            [ 45, 110, 95, 115]]

    rows = cost.length
    cols = cost[0].length

    assignment = ORTools::LinearSumAssignment.new
    rows.times do |worker|
      cols.times do |task|
        if cost[worker][task]
          assignment.add_arc_with_cost(worker, task, cost[worker][task])
        end
      end
    end

    assert_equal :optimal, assignment.solve
    assert_equal 265, assignment.optimal_cost
    assert_equal 4, assignment.num_nodes

    nodes = assignment.num_nodes.times
    assert_equal [3, 2, 1, 0], nodes.map { |i| assignment.right_mate(i) }
    assert_equal [70, 55, 95, 45], nodes.map { |i| assignment.assignment_cost(i) }
  end

  def test_assignment_min_cost_flow
    min_cost_flow = ORTools::SimpleMinCostFlow.new

    start_nodes = [0, 0, 0, 0] + [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4] + [5, 6, 7, 8]
    end_nodes =   [1, 2, 3, 4] + [5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8] + [9, 9, 9, 9]
    capacities =  [1, 1, 1, 1] + [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] + [1, 1, 1, 1]
    costs  = [0, 0, 0, 0] + [90, 76, 75, 70, 35, 85, 55, 65, 125, 95, 90, 105, 45, 110, 95, 115] + [0, 0, 0, 0]
    supplies = [4, 0, 0, 0, 0, 0, 0, 0, 0, -4]
    source = 0
    sink = 9
    tasks = 4

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
