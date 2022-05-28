require_relative "test_helper"

class IntegerTest < Minitest::Test
  # https://developers.google.com/optimization/mip/mip_example
  def test_solver
    solver = ORTools::Solver.new("CBC")

    infinity = solver.infinity
    x = solver.int_var(0, infinity, "x")
    y = solver.int_var(0, infinity, "y")

    assert_equal 2, solver.num_variables

    solver.add(x + 7 * y <= 17.5)

    solver.add(x <= 3.5)

    assert_equal 2, solver.num_constraints

    solver.maximize(x + 10 * y)

    assert_equal :optimal, solver.solve
    assert_equal 23, solver.objective.value
    assert_equal 3, x.solution_value
    assert_equal 2, y.solution_value

    assert solver.wall_time
    assert_equal 1, solver.iterations
    assert_equal 0, solver.nodes
  end
end
