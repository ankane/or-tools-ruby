require_relative "test_helper"

class LinearTest < Minitest::Test
  # https://developers.google.com/optimization/lp/glop
  def test_solver
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)

    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")

    constraint0 = solver.constraint(-solver.infinity, 14)
    constraint0.set_coefficient(x, 1)
    constraint0.set_coefficient(y, 2)

    constraint1 = solver.constraint(0, solver.infinity)
    constraint1.set_coefficient(x, 3)
    constraint1.set_coefficient(y, -1)

    constraint2 = solver.constraint(-solver.infinity, 2)
    constraint2.set_coefficient(x, 1)
    constraint2.set_coefficient(y, -1)

    # solver.add(x + y * 2 <= 14)
    # solver.add(x*3 + y >= 0)
    # solver.add(x - y <= 2)

    objective = solver.objective
    objective.set_coefficient(x, 3)
    objective.set_coefficient(y, 4)
    objective.set_maximization

    solver.solve

    opt_solution = 3 * x.solution_value + 4 * y.solution_value
    assert_equal 2, solver.num_variables
    assert_equal 3, solver.num_constraints
    assert_in_delta 6, x.solution_value
    assert_in_delta 4, y.solution_value
    assert_in_delta 34, opt_solution
  end
end
