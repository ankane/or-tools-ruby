require_relative "test_helper"

class MathOptTest < Minitest::Test
  # https://developers.google.com/optimization/math_opt/basic_example
  def test_basic
    model = ORTools::MathOpt::Model.new("getting_started_lp")
    x = model.add_variable(-1.0, 1.5, "x")
    y = model.add_variable(0.0, 1.0, "y")

    skip "todo"

    model.add_linear_constraint(x + y <= 1.5)
    model.maximize(x + 2 * y)

    params = ORTools::MathOpt::SolveParameters.new(enable_output: true)

    result = mathopt.solve(model, :glop, params)
    if result.termination.reason != :optimal
      raise RuntimeError, "model failed to solve: #{result.termination}"
    end

    puts "MathOpt solve succeeded"
    puts "Objective value:", result.objective_value
    puts "x:", result.variable_values[x]
    puts "y:", result.variable_values[y]
  end
end
