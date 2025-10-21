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
    # declare the model
    model = ORTools::CpModel.new

    # create the variables
    num_vals = 3
    x = model.new_int_var(0, num_vals - 1, "x")
    y = model.new_int_var(0, num_vals - 1, "y")
    z = model.new_int_var(0, num_vals - 1, "z")

    # create the constraint
    model.add(x != y)

    # call the solver
    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    # display the first solution
    if status == :optimal || status == :feasible
      puts "x = #{solver.value(x)}"
      puts "y = #{solver.value(y)}"
      puts "z = #{solver.value(z)}"
    else
      puts "No solution found."
    end

    assert_output <<~EOS
      x = 1
      y = 0
      z = 0
    EOS
  end

  # https://developers.google.com/optimization/cp/cp_example
  def test_optimization
    # declare the model
    model = ORTools::CpModel.new

    # create the variables
    var_upper_bound = [50, 45, 37].max
    x = model.new_int_var(0, var_upper_bound, "x")
    y = model.new_int_var(0, var_upper_bound, "y")
    z = model.new_int_var(0, var_upper_bound, "z")

    # define the constraints
    model.add(x*2 + y*7 + z*3 <= 50)
    model.add(x*3 - y*5 + z*7 <= 45)
    model.add(x*5 + y*2 - z*6 <= 37)

    # define the objective function
    model.maximize(x*2 + y*2 + z*3)

    # call the solver
    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    # display the solution
    if status == :optimal || status == :feasible
      puts "Maximum of objective function: #{solver.objective_value}"
      puts "x = #{solver.value(x)}"
      puts "y = #{solver.value(y)}"
      puts "z = #{solver.value(z)}"
    else
      puts "No solution found."
    end

    assert_output <<~EOS
      Maximum of objective function: 35.0
      x = 7
      y = 3
      z = 5
    EOS
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
    solver.parameters.enumerate_all_solutions = true
    solution_printer = VarArraySolutionPrinter.new(letters)
    status = solver.solve(model, solution_printer)
    assert_equal :optimal, status

    assert_equal 184, solver.num_conflicts
    assert_equal 1850, solver.num_branches
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
    solver.parameters.enumerate_all_solutions = true
    solution_printer = DiagramPrinter.new(queens)
    status = solver.solve(model, solution_printer)
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

  def test_infeasible_value
    model = ORTools::CpModel.new

    x = model.new_bool_var("x")
    model.add(x > 1)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)

    assert_equal :infeasible, status
    error = assert_raises(ORTools::Error) do
      solver.value(x)
    end
    assert_equal "No solution found", error.message
  end

  def test_add_hint
    model = ORTools::CpModel.new

    x = model.new_int_var(0, 1, "x")
    y = model.new_bool_var("y")

    model.add_hint(x, 1)
    model.add_hint(y, true)

    error = assert_raises(RuntimeError) do
      model.add_hint("z", 1)
    end
    assert_equal "The provided Ruby object does not wrap a C++ object", error.message
  end

  def test_int_var_domain
    model = ORTools::CpModel.new

    lower_bound = (0..9).to_a.sample
    upper_bound = (10..19).to_a.sample
    x = model.new_int_var(lower_bound, upper_bound, "x")

    assert_equal lower_bound, x.domain.min
    assert_equal upper_bound, x.domain.max
  end

  def test_sum_empty_true
    model = ORTools::CpModel.new
    model.add([].sum < 2)
    expected = <<~EOS
      variables {
        domain: 1
        domain: 1
      }
      constraints {
        bool_or {
          literals: 0
        }
      }
    EOS
    assert_equal expected, model.inspect
  end

  def test_sum_empty_false
    model = ORTools::CpModel.new
    model.add([].sum > 2)
    expected = <<~EOS
      constraints {
        bool_or {
        }
      }
    EOS
    assert_equal expected, model.inspect
  end

  def test_add_not_supported
    model = ORTools::CpModel.new
    error = assert_raises(TypeError) do
      model.add("x")
    end
    assert_equal "Not supported: CpModel#add(x)", error.message
  end

  def test_domain_from_values
    domain = ORTools::Domain.from_values([1, 2, 3])
    assert_equal 1, domain.min
    assert_equal 3, domain.max
  end

  def test_automaton_consecutive_limit
    model = ORTools::CpModel.new

    # a small sequence of binary variables
    n = 8
    xs = n.times.map { |i| model.new_bool_var("x#{i}") }

    # Build automaton for "at most 2 consecutive 1s"
    limit = 2
    transitions = []
    (0..limit).each { |s| transitions << [s, 0, 0] }       # on 0: reset to 0
    (0...limit).each { |s| transitions << [s, 1, s + 1] }  # on 1: increment (no 1 from state=limit)
    finals = (0..limit).to_a
    start_state = 0

    # Add automaton constraint and push solver to use 1s when possible
    model.add_automaton(xs, start_state, finals, transitions)
    model.maximize(model.sum(xs))

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert([:optimal, :feasible].include?(status), "Unexpected status: #{status}")

    values = xs.map { |x| solver.value(x) }
    consec = 0
    ok = true
    values.each do |v|
      if v == 1
        consec += 1
        if consec > limit
          ok = false
          break
        end
      else
        consec = 0
      end
    end
    assert ok, "Found more than #{limit} consecutive 1s: #{values.inspect}"
  end
end
