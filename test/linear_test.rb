require_relative "test_helper"

class LinearTest < Minitest::Test
  # https://developers.google.com/optimization/lp/glop
  def test_solver
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)

    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")

    solver.add(x + 2 * y <= 14)
    solver.add(3 * x - y >= 0)
    solver.add(x - y <= 2)
    solver.maximize(3 * x + 4 * y)

    solver.solve

    opt_solution = 3 * x.solution_value + 4 * y.solution_value
    assert_equal 2, solver.num_variables
    assert_equal 3, solver.num_constraints
    assert_in_delta 6, x.solution_value
    assert_in_delta 4, y.solution_value
    assert_in_delta 34, opt_solution

    assert_match "Obj: +3 V0 +4 V1", solver.export_model_as_lp_format(true)
    assert_match "Obj: +3 x +4 y", solver.export_model_as_lp_format(false)
    assert_match "OBJSENSE", solver.export_model_as_mps_format(true, true)
  end

  def test_type_error
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
    x = solver.num_var(0, solver.infinity, "x")

    error = assert_raises(TypeError) do
      x * x
    end
    assert_equal "expected numeric", error.message
  end

  def test_to_s
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")

    assert_equal "x", x.to_s
    assert_equal "(x + (2 * y))", (x + y * 2).to_s
    assert_equal "(x + (2 * y)) <= 14", (x + y * 2 <= 14).to_s
    assert_equal "(x + 1)", (x + 1).to_s
    assert_equal "(x + y + 1 + 2)", solver.sum([x, y, 1, 2]).to_s
    assert_equal "((x + 1) + (y + 2))", (solver.sum([x, 1]) + solver.sum([y, 2])).to_s
    assert_equal "(2 * (x + (2 * y)))", ((x + y * 2) * 2).to_s
  end

  def test_inspect
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
    x = solver.num_var(0, solver.infinity, "x")

    assert_equal "#<ORTools::MPVariable x>", x.inspect
    assert_equal "#<ORTools::SumArray (x + 1)>", (x + 1).inspect
    assert_equal "#<ORTools::LinearExpr (empty)>", ORTools::LinearExpr.new.inspect
    assert_equal "#<ORTools::LinearConstraint (x + 1) == 1>", (x + 1 == 1).inspect
  end
end
