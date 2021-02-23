require_relative "test_helper"

class SolutionPrinterTest < Minitest::Test
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
    assert_equal 15, solution_printer.solution_count
    assert_match "Solution 14", stdout
  end

  def test_var_array_solution_printer
    model = ORTools::CpModel.new
    x = model.new_int_var(-7, 7, "x")
    y = model.new_int_var(0, 7, "y")
    model.add_max_equality(y, [x, model.new_constant(0)])

    solver = ORTools::CpSolver.new
    solution_printer = ORTools::VarArraySolutionPrinter.new([x, y])
    stdout, _ = capture_io do
      solver.search_for_all_solutions(model, solution_printer)
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
    solution_printer = ORTools::VarArrayAndObjectiveSolutionPrinter.new([x, y])
    stdout, _ = capture_io do
      solver.search_for_all_solutions(model, solution_printer)
    end
    assert_equal 15, solution_printer.solution_count
    assert_match "Solution 14", stdout
  end
end
