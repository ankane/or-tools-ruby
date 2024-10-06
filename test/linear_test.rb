require_relative "test_helper"

class LinearTest < Minitest::Test
  # https://developers.google.com/optimization/lp/lp_example
  def test_solver
    solver = ORTools::Solver.new("GLOP")

    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")
    assert_equal 2, solver.num_variables

    solver.add(x + 2 * y <= 14)
    solver.add(3 * x - y >= 0)
    solver.add(x - y <= 2)
    assert_equal 3, solver.num_constraints

    solver.maximize(3 * x + 4 * y)

    assert_equal :optimal, solver.solve

    assert_in_delta 34, solver.objective.value
    assert_in_delta 6, x.solution_value
    assert_in_delta 4, y.solution_value

    assert_match "Obj: +3 V0 +4 V1", solver.export_model_as_lp_format(true)
    assert_match "Obj: +3 x +4 y", solver.export_model_as_lp_format(false)
    assert_match "OBJSENSE", solver.export_model_as_mps_format(true, true)
  end

  def test_type_error
    # use new instead of create for now to test
    solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
    x = solver.num_var(0, solver.infinity, "x")

    error = assert_raises(ArgumentError) do
      solver.maximize(x * x)
    end
    assert_equal "Nonlinear", error.message
  end

  def test_to_s
    solver = ORTools::Solver.new("GLOP")
    x = solver.num_var(0, solver.infinity, "x")
    y = solver.num_var(0, solver.infinity, "y")

    assert_equal "x", x.to_s
    assert_equal "x + 2 * y", (x + 2 * y).to_s
    assert_equal "x + 2 * y <= 14", (x + 2 * y <= 14).to_s
    assert_equal "x + 1", (x + 1).to_s
    assert_equal "x + y + 1 + 2", [x, y, 1, 2].sum.to_s
    assert_equal "x + 1 + y + 2", ([x, 1].sum + [y, 2].sum).to_s
    assert_equal "2 * (x + 2 * y)", (2 * (x + 2 * y)).to_s
    assert_equal "2 * (x + 2 * y)", (2 * [x, 2 * y].sum).to_s
    assert_equal "-x", (-x).to_s
    assert_equal "-x", [-x].sum.to_s
    assert_equal "x - 2", [x, -2].sum.to_s
    assert_equal "x - x", [x, -x].sum.to_s
    assert_equal "-2 + x", [-2, x].sum.to_s
    assert_equal "x + y", [x, 0, y, 0].sum.to_s
  end

  def test_inspect
    solver = ORTools::Solver.new("GLOP")
    x = solver.num_var(0, solver.infinity, "x")

    assert_equal "x", x.inspect
    assert_equal "x + 1", (x + 1).inspect
    assert_equal "x + 1 == 1", (x + 1 == 1).inspect
  end

  def test_offset
    solver = ORTools::Solver.new("GLOP")
    x = solver.num_var(0, 1, "x")
    solver.minimize(x + 2)
    assert_equal :optimal, solver.solve
    assert_equal 2, solver.objective.value
  end

  def test_infeasible_value
    solver = ORTools::Solver.new("GLOP")

    x = solver.num_var(0, 1, "x")
    solver.add(x >= 2)
    status = solver.solve

    assert_equal :infeasible, status
    assert_equal 0, x.solution_value
  end

  # Python returns nil,
  # but since we use new (which should return instance of class),
  # raising an exception seems better
  def test_unrecognized_solver_type
    error = assert_raises do
      ORTools::Solver.new("UNKNOWN")
    end
    assert_equal "Unrecognized solver type", error.message
  end
end
