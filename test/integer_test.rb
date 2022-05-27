require_relative "test_helper"

class IntegerTest < Minitest::Test
  # https://developers.google.com/optimization/mip/integer_opt
  def test_solver
    solver = ORTools::Solver.new("simple_mip_program", :cbc)

    infinity = solver.infinity
    x = solver.int_var(0, infinity, "x")
    y = solver.int_var(0, infinity, "y")

    assert_equal 2, solver.num_variables

    # solver.add(x + 7 * y <= 17.5)
    c0 = solver.constraint(-infinity, 17.5)
    c0.set_coefficient(x, 1)
    c0.set_coefficient(y, 7)

    # solver.add(x <= 3.5)
    c1 = solver.constraint(-infinity, 3.5)
    c1.set_coefficient(x, 1);
    c1.set_coefficient(y, 0);

    assert_equal 2, solver.num_constraints

    # solver.maximize(x + 10 * y)
    objective = solver.objective
    objective.set_coefficient(x, 1)
    objective.set_coefficient(y, 10)
    objective.set_maximization

    assert_equal :optimal, solver.solve
    assert_equal 23, solver.objective.value
    assert_equal 3, x.solution_value
    assert_equal 2, y.solution_value

    assert solver.wall_time
    assert_equal 1, solver.iterations
    assert_equal 0, solver.nodes
  end
end
