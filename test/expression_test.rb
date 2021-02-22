require_relative "test_helper"

class ExpressionTest < Minitest::Test
  def test_optimal
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    y = model.new_int_var(0, 1, "y")
    model.add(y == -x + 1)
    model.add(y == -x + 2 - 1)
    model.add(y * 2 == x * -2 + 2)

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal 1, solver.value(x)
    assert_equal 0, solver.value(y)
  end

  def test_infeasible
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    y = model.new_int_var(0, 1, "y")
    model.add(y == -x - 1)

    solver = ORTools::CpSolver.new
    assert_equal :infeasible, solver.solve(model)
  end

  def test_add_max_equality
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])
    # TODO support
    # model.add_max_equality(y, [x, 0])

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal(-7, solver.value(x))
    assert_equal 0, solver.value(y)
  end
end
