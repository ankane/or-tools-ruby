require_relative "test_helper"

class ConstraintTest < Minitest::Test
  # https://developers.google.com/optimization/cp/cp_solver
  def test_cp_sat_solver
    model = ORTools::CpModel.new

    num_vals = 3
    x = model.new_int_var(0, num_vals - 1, "x")
    y = model.new_int_var(0, num_vals - 1, "y")
    z = model.new_int_var(0, num_vals - 1, "z")

    model.add(x != y)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :feasible, status
    assert_equal 1, solver.value(x)
    assert_equal 2, solver.value(y)
    assert_equal 0, solver.value(z)
  end

  def test_optimization
    model = ORTools::CpModel.new
    var_upper_bound = [50, 45, 37].max
    x = model.new_int_var(0, var_upper_bound, "x")
    y = model.new_int_var(0, var_upper_bound, "y")
    z = model.new_int_var(0, var_upper_bound, "z")

    model.add(x*2 + y*7 + z*3 <= 50)
    model.add(x*3 - y*5 + z*7 <= 45)
    model.add(x*5 + y*2 - z*6 <= 37)

    model.maximize(x*2 + y*2 + z*3)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :optimal, status
    # assert_equal 35, solver.objective_value
    assert_equal 7, solver.value(x)
    assert_equal 3, solver.value(y)
    assert_equal 5, solver.value(z)
  end
end
