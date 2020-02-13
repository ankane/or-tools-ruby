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
end
