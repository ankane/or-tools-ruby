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
    assert_equal 0, solver.value(x)
    assert_equal 1, solver.value(y)
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
    assert_equal(0, solver.value(x))
    assert_equal 0, solver.value(y)
  end

  def test_only_enforce_if
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    model.add(x == x + 1).only_enforce_if(x)

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal(0, solver.value(x))
  end

  def test_only_enforce_if_array
    model = ORTools::CpModel.new
    x = model.new_bool_var("x")
    model.add(x != x).only_enforce_if([x])

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal false, solver.value(x)
  end

  def test_only_enforce_if_int_array
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    model.add(x == x + 1).only_enforce_if([x])

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal 0, solver.value(x)
  end

  def test_add_assumption
    model = ORTools::CpModel.new
    x = model.new_bool_var("x")
    model.add_assumption(x)

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal true, solver.value(x)
  end

  def test_add_assumptions
    model = ORTools::CpModel.new
    x = model.new_bool_var("x")
    model.add_assumptions([x])

    solver = ORTools::CpSolver.new
    assert_equal :optimal, solver.solve(model)
    assert_equal true, solver.value(x)
  end

  def test_to_s
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    y = model.new_int_var(0, 1, "y")
    z = model.new_int_var(0, 1, "z")
    # model.add(model.sum([x, y]) == z)
    model.add(x + y == z)

    output = model.to_s
    assert_match "variables", output
    assert_match "constraints", output

    # TODO
    # assert_equal File.binread("test/support/proto.txt"), output

    assert_equal "x", x.to_s
    assert_equal "x + y", (x + y).to_s
    assert_equal "x + y == z", (x + y == z).to_s
  end

  def test_inspect
    model = ORTools::CpModel.new
    x = model.new_int_var(0, 1, "x")
    y = model.new_int_var(0, 1, "y")
    z = model.new_int_var(0, 1, "z")

    assert_equal "#<ORTools::SatIntVar x>", x.inspect
    assert_equal "#<ORTools::SatLinearExpr x + y>", (x + y).inspect
    assert_equal "#<ORTools::Comparison x + y == z>", (x + y == z).inspect
  end
end
