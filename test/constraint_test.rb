require_relative "test_helper"

class VarArraySolutionPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(variables)
    super()
    @variables = variables
    @solution_count = 0
  end

  def on_solution_callback
    @solution_count += 1
    # @variables.each do |v|
    #   print "%s=%i " % [v.name, value(v)]
    # end
    # puts
  end
end

class DiagramPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(variables)
    super()
    @variables = variables
    @solution_count = 0
  end

  def on_solution_callback
    @solution_count += 1

    # @variables.each do |v|
    #   queen_col = value(v)
    #   board_size = @variables.size

    #   board_size.times do |j|
    #     if j == queen_col
    #       print("Q ")
    #     else
    #       print("_ ")
    #     end
    #   end
    #   puts
    # end
    # puts
  end
end

class ConstraintTest < Minitest::Test
  # https://developers.google.com/optimization/cp/cp_solver
  def test_cp_sat_solver
    model = ORTools::CpModel.new

    num_vals = 3
    x = model.new_int_var(0, num_vals - 1, "x")
    y = model.new_int_var(0, num_vals - 1, "y")
    z = model.new_int_var(0, num_vals - 1, "z")

    model.add(x != y)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :optimal, status
    assert_equal 1, solver.value(x)
    assert_equal 0, solver.value(y)
    assert_equal 0, solver.value(z)
  end

  # https://developers.google.com/optimization/cp/integer_opt_cp
  def test_optimization
    model = ORTools::CpModel.new
    var_upper_bound = [50, 45, 37].max
    x = model.new_int_var(0, var_upper_bound, "x")
    y = model.new_int_var(0, var_upper_bound, "y")
    z = model.new_int_var(0, var_upper_bound, "z")

    model.add(x*2 + y*7 + z*3 <= 50)
    model.add(x*3 - y*5 + z*7 <= 45)
    model.add(x*5 + y*2 - z*6 <= 37)

    model.maximize(x*2 + y*2 + z*3)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :optimal, status
    assert_equal 35, solver.objective_value
    assert_equal 7, solver.value(x)
    assert_equal 3, solver.value(y)
    assert_equal 5, solver.value(z)
  end

  # https://developers.google.com/optimization/cp/cryptarithmetic
  def test_cryptoarithmetic
    model = ORTools::CpModel.new

    base = 10

    c = model.new_int_var(1, base - 1, "C")
    p = model.new_int_var(0, base - 1, "P")
    i = model.new_int_var(1, base - 1, "I")
    s = model.new_int_var(0, base - 1, "S")
    f = model.new_int_var(1, base - 1, "F")
    u = model.new_int_var(0, base - 1, "U")
    n = model.new_int_var(0, base - 1, "N")
    t = model.new_int_var(1, base - 1, "T")
    r = model.new_int_var(0, base - 1, "R")
    e = model.new_int_var(0, base - 1, "E")

    letters = [c, p, i, s, f, u, n, t, r, e]

    model.add_all_different(letters)

    model.add(c * base + p + i * base + s + f * base * base + u * base +
      n == t * base * base * base + r * base * base + u * base + e)

    solver = ORTools::CpSolver.new
    solution_printer = VarArraySolutionPrinter.new(letters)
    status = solver.search_for_all_solutions(model, solution_printer)
    assert_equal :optimal, status

    assert_equal 179, solver.num_conflicts
    assert_equal 828, solver.num_branches
    assert_equal 72, solution_printer.solution_count
  end

  # https://developers.google.com/optimization/cp/queens
  def test_queens
    board_size = 8

    model = ORTools::CpModel.new
    queens = board_size.times.map { |i| model.new_int_var(0, board_size - 1, "x%i" % i) }

    model.add_all_different(queens)

    board_size.times do |i|
      diag1 = []
      diag2 = []
      board_size.times do |j|
        q1 = model.new_int_var(0, 2 * board_size, "diag1_%i" % i)
        diag1 << q1
        model.add(q1 == queens[j] + j)
        q2 = model.new_int_var(-board_size, board_size, "diag2_%i" % i)
        diag2 << q2
        model.add(q2 == queens[j] - j)
      end
      model.add_all_different(diag1)
      model.add_all_different(diag2)
    end

    solver = ORTools::CpSolver.new
    solution_printer = DiagramPrinter.new(queens)
    status = solver.search_for_all_solutions(model, solution_printer)
    assert_equal :optimal, status
    assert_equal 92, solution_printer.solution_count
  end

  def test_time_limit
    model = ORTools::CpModel.new
    num_vals = 3
    x = model.new_int_var(0, num_vals - 1, "x")
    y = model.new_int_var(0, num_vals - 1, "y")
    model.add(x != y)

    solver = ORTools::CpSolver.new
    solver.parameters.max_time_in_seconds = 0

    status = solver.solve(model)
    assert_equal :unknown, status
  end
end
