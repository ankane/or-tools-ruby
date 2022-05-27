require_relative "test_helper"

class AssignmentTest < Minitest::Test
  # https://developers.google.com/optimization/assignment/linear_assignment
  def test_linear_sum_assignment
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

  # https://developers.google.com/optimization/assignment/assignment_teams#mip
  def test_assignment_teams
    solver = ORTools::Solver.create("CBC")

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

    num_workers.times do |i|
      solver.add(num_tasks.times.sum { |j| x[[i, j]] } <= 1)
    end

    num_tasks.times do |j|
      solver.add(num_workers.times.sum { |i| x[[i, j]] } == 1)
    end

    solver.add(team1.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }.sum <= team_max)
    solver.add(team2.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }.sum <= team_max)

    # create the objective
    solver.minimize(
      num_workers.times.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] * cost[i][j] } }.sum
    )

    status = solver.solve
    assert_equal :optimal, status

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
