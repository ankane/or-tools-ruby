require_relative "test_helper"

class ExpressionTest < Minitest::Test
  def test_expressions
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    y = model.new_int_var(0, 1, "y")
    model.add(y == -x + 1)

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal 1, solver.value(x)
    assert_equal 0, solver.value(y)
  end
end
