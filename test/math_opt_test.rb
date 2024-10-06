require_relative "test_helper"

class MathOptTest < Minitest::Test
  # https://developers.google.com/optimization/math_opt/basic_example
  def test_basic
    model = ORTools::MathOpt::Model.new("getting_started_lp")
    x = model.add_variable(-1.0, 1.5, "x")
    y = model.add_variable(0.0, 1.0, "y")
    model.add_linear_constraint(x + y <= 1.5)
    model.maximize(x + 2 * y)

    result = model.solve

    puts "Objective value: #{result.objective_value}"
    puts "x: #{result.variable_values[x]}"
    puts "y: #{result.variable_values[y]}"

    assert_output <<~EOS
      Objective value: 2.5
      x: 0.5
      y: 1.0
    EOS
  end

  def test_minimize
    model = ORTools::MathOpt::Model.new("getting_started_lp")
    x = model.add_variable(-1.0, 1.5, "x")
    y = model.add_variable(0.0, 1.0, "y")
    model.add_linear_constraint(x + y >= 0.5)
    model.minimize(x + 2 * y)

    result = model.solve

    assert_equal 0.5, result.objective_value
    assert_equal 0.5, result.variable_values[x]
    assert_equal 0, result.variable_values[y]
  end
end
