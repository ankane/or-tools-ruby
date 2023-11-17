require_relative "test_helper"

class SolutionInfoSat < Minitest::Test
  def test_solution_info_sat
    model = ORTools::CpModel.new

    x = model.new_int_var(0, 10, 'x')
    y = model.new_int_var(0, 10, 'y')
    z = model.new_int_var(0, 10, 'z')

    model.add_division_equality(x, y, z)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :model_invalid, status
    assert_match "The domain of the divisor cannot contain 0", solver.solution_info
  end
end
