require_relative "test_helper"

class AssignmentTest < Minitest::Test
  # https://developers.google.com/optimization/assignment/assignment_example
  def test_assignment
    # create the data
    costs = [
      [90, 80, 75, 70],
      [35, 85, 55, 65],
      [125, 95, 90, 95],
      [45, 110, 95, 115],
      [50, 100, 90, 100]
    ]
    num_workers = costs.length
    num_tasks = costs[0].length

    # create the solver
    solver = ORTools::Solver.create("CBC")

    # create the variables
    x = {}
    num_workers.times do |i|
      num_tasks.times do |j|
        x[[i, j]] = solver.int_var(0, 1, "")
      end
    end

    # create the constraints
    # each worker is assigned to at most 1 task
    num_workers.times do |i|
      solver.add(num_tasks.times.sum { |j| x[[i, j]] } <= 1)
    end

    # each task is assigned to exactly one worker
    num_tasks.times do |j|
      solver.add(num_workers.times.sum { |i| x[[i, j]] } == 1)
    end

    # create the objective function
    objective_terms = []
    num_workers.times do |i|
      num_tasks.times do |j|
        objective_terms << (costs[i][j] * x[[i, j]])
      end
    end
    solver.minimize(objective_terms.sum)

    # invoke the solver
    status = solver.solve

    # print the solution
    if status == :optimal || status == :feasible
      puts "Total cost = #{solver.objective.value}"
      num_workers.times do |i|
        num_tasks.times do |j|
          # test if x[i,j] is 1 (with tolerance for floating point arithmetic)
          if x[[i, j]].solution_value > 0.5
            puts "Worker #{i} assigned to task #{j}. Cost: #{costs[i][j]}"
          end
        end
      end
    else
      puts "No solution found."
    end

    assert_output <<~EOS
      Total cost = 265.0
      Worker 0 assigned to task 3. Cost: 70
      Worker 1 assigned to task 2. Cost: 55
      Worker 2 assigned to task 1. Cost: 95
      Worker 3 assigned to task 0. Cost: 45
    EOS
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
end
