require_relative "test_helper"

class AssumptionsSampleSat < Minitest::Test
  def test_assumptions_sample_sats
    model = ORTools::CpModel.new

    x = model.new_int_var(0, 10, 'x')
    y = model.new_int_var(0, 10, 'y')
    z = model.new_int_var(0, 10, 'z')
    a = model.new_bool_var('a')
    b = model.new_bool_var('b')
    c = model.new_bool_var('c')

    model.add(x > y).only_enforce_if(a)
    model.add(y > z).only_enforce_if(b)
    model.add(z > x).only_enforce_if(c)

    # Add assumptions
    model.add_assumptions([a, b, c])

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :feasible, status

    puts('status: %s' % status)
    puts('SufficientAssumptionsForInfeasibility = %s' % solver.sufficient_assumptions_for_infeasibility)
  end
end
