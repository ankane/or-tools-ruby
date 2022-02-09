require_relative "test_helper"

class LinearTest < Minitest::Test
  # https://developers.google.com/optimization/lp/glop
  def test_solver
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)

    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")

    # constraint0 = solver.constraint(-solver.infinity, 14)
    # constraint0.set_coefficient(x, 1)
    # constraint0.set_coefficient(y, 2)

    # constraint1 = solver.constraint(0, solver.infinity)
    # constraint1.set_coefficient(x, 3)
    # constraint1.set_coefficient(y, -1)

    # constraint2 = solver.constraint(-solver.infinity, 2)
    # constraint2.set_coefficient(x, 1)
    # constraint2.set_coefficient(y, -1)

    # objective = solver.objective
    # objective.set_coefficient(x, 3)
    # objective.set_coefficient(y, 4)
    # objective.set_maximization

    solver.add(x + y * 2 <= 14)
    solver.add(x*3 + y >= 0)
    solver.add(x + y * -1 <= 2)
    solver.maximize(x * 3 + y * 4)

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
  end

  def test_inspect
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
    x = solver.num_var(0, solver.infinity, "x")

    assert_equal "#<ORTools::MPVariable x>", x.inspect
    assert_equal "#<ORTools::SumArray (x + 1)>", (x + 1).inspect
    assert_equal "#<ORTools::LinearExpr (empty)>", ORTools::LinearExpr.new.inspect
  end
end
