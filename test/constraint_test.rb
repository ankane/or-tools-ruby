require_relative "test_helper"

class ConstraintTest < Minitest::Test
  # https://developers.google.com/optimization/cp/cp_solver
  def test_cp_sat_solver
    model = ORTools::CpModel.new

    num_vals = 3
    x = model.new_int_var(0, num_vals - 1, "x")
    y = model.new_int_var(0, num_vals - 1, "y")
    z = model.new_int_var(0, num_vals - 1, "z")

    model.add_not_equal(x, y)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :feasible, status
    assert_equal 1, solver.value(x)
    assert_equal 2, solver.value(y)
    assert_equal 0, solver.value(z)
  end
end
