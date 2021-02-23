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

  def test_objective_solution_printer
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solution_printer = ORTools::ObjectiveSolutionPrinter.new
    stdout, _ = capture_io do
      solver.search_for_all_solutions(model, solution_printer)
    end
    assert_match "Solution 14", stdout
    refute_match "Solution 15", stdout
  end

  def test_inspect
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    output = model.inspect
    assert_match "variables", output
    assert_match "constraints", output
  end
end
