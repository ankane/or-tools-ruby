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

  # https://developers.google.com/optimization/assignment/assignment_mip
  def test_assignment_mip
    solver = ORTools::Solver.new("SolveAssignmentProblemMIP", :cbc)

    cost = [[90, 76, 75, 70],
            [35, 85, 55, 65],
            [125, 95, 90, 105],
            [45, 110, 95, 115],
            [60, 105, 80, 75],
            [45, 65, 110, 95]]

    team1 = [0, 2, 4]
    team2 = [1, 3, 5]
    team_max = 2

    num_workers = cost.length
    num_tasks = cost[1].length
    x = {}

    num_workers.times do |i|
      num_tasks.times do |j|
        x[[i, j]] = solver.bool_var("x[#{i},#{j}]")
      end
    end

    solver.minimize(solver.sum(
      num_workers.times.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] * cost[i][j] } }
    ))

    num_workers.times do |i|
      solver.add(solver.sum(num_tasks.times.map { |j| x[[i, j]] }) <= 1)
    end

    num_tasks.times do |j|
      solver.add(solver.sum(num_workers.times.map { |i| x[[i, j]] }) == 1)
    end

    solver.add(solver.sum(team1.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)
    solver.add(solver.sum(team2.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)
    sol = solver.solve
    assert_equal :optimal, sol

    assert_equal 250, solver.objective.value

    assignments = []
    num_workers.times do |i|
      num_tasks.times do |j|
        if x[[i, j]].solution_value > 0
          assignments << [i, j]
        end
      end
    end

    assert_equal [[0, 2], [1, 0], [4, 3], [5, 1]], assignments
  end
end
