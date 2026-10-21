require_relative "test_helper"

class SolutionPrinterTest < Minitest::Test
  def test_objective_solution_printer
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solver.parameters.enumerate_all_solutions = true
    solution_printer = ORTools::ObjectiveSolutionPrinter.new
    assert_nil solution_printer.objective_value

    stdout, _ = capture_io do
      solver.solve(model, solution_printer)
    end
    assert_equal 15, solution_printer.solution_count
    assert_match "Solution 14", stdout

    # ensure @response is still valid after solve
    GC.start
    assert_equal 0, solution_printer.objective_value
    assert_equal 0, solution_printer.best_objective_bound
    assert_equal 14, solution_printer.num_booleans
    assert_equal 0, solution_printer.num_conflicts
    assert_equal 14, solution_printer.num_branches
    assert_equal 49, solution_printer.num_integer_propagations
    assert_equal 14, solution_printer.num_binary_propagations
    assert_kind_of Float, solution_printer.deterministic_time
    assert_kind_of Float, solution_printer.wall_time
    assert_kind_of Float, solution_printer.user_time
  end

  def test_var_array_solution_printer
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solver.parameters.enumerate_all_solutions = true
    solution_printer = ORTools::VarArraySolutionPrinter.new([x, y])
    stdout, _ = capture_io do
      solver.solve(model, solution_printer)
    end
    assert_equal 15, solution_printer.solution_count
    assert_match "Solution 14", stdout
  end

  def test_var_array_and_objective_solution_printer
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solver.parameters.enumerate_all_solutions = true
    solution_printer = ORTools::VarArrayAndObjectiveSolutionPrinter.new([x, y])
    stdout, _ = capture_io do
      solver.solve(model, solution_printer)
    end
    assert_equal 15, solution_printer.solution_count
    assert_match "Solution 14", stdout
  end

  def test_not_solved
    solution_printer = ORTools::ObjectiveSolutionPrinter.new
    error = assert_raises do
      solution_printer.best_objective_bound
    end
    assert_equal "solve() has not been called.", error.message
  end
end
