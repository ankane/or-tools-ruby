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

  def test_objective_solution_printer_with_multiple_workers
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solver.parameters.num_workers = 4
    solution_printer = ORTools::ObjectiveSolutionPrinter.new

    capture_io do
      solver.solve(model, solution_printer)
    end
    assert solution_printer.solution_count >= 1

    GC.start
    assert_equal 0, solution_printer.objective_value
  end
end
