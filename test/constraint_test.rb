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

  def test_bool_cardinality_constraints
    model = ORTools::CpModel.new
    a = model.new_bool_var("a")
    b = model.new_bool_var("b")
    c = model.new_bool_var("c")

    model.add_at_least_one([a, b])
    model.add_at_most_one([a, b])
    model.add_exactly_one([b, c])

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status

    a_val = solver.value(a) ? 1 : 0
    b_val = solver.value(b) ? 1 : 0
    c_val = solver.value(c) ? 1 : 0

    assert_equal 1, a_val + b_val
    assert_equal 1, b_val + c_val
  end

  def test_element_constraints
    model = ORTools::CpModel.new
    index = model.new_int_var(0, 2, "index")
    model.add(index == 2)

    const_target = model.new_int_var(0, 10, "const_target")
    model.add_element(index, [3, 5, 7], const_target)

    v0 = model.new_int_var(0, 30, "v0")
    v1 = model.new_int_var(0, 30, "v1")
    v2 = model.new_int_var(0, 30, "v2")
    model.add(v0 == 10)
    model.add(v1 == 20)
    model.add(v2 == 30)

    var_target = model.new_int_var(0, 40, "var_target")
    model.add_variable_element(index, [v0, v1, v2], var_target)

    expr_target = model.new_int_var(0, 50, "expr_target")
    exprs = [v0 + 1, v1 + 1, v2 + 1]
    model.add_element(index, exprs, expr_target)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal 7, solver.value(const_target)
    assert_equal 30, solver.value(var_target)
    assert_equal 31, solver.value(expr_target)
  end

  def test_circuit_constraint
    model = ORTools::CpModel.new
    arcs = [[0, 1], [1, 2], [2, 0], [0, 2], [2, 1], [1, 0]]
    literals = arcs.map { |tail, head| model.new_bool_var("arc_#{tail}_#{head}") }

    circuit = model.add_circuit_constraint
    arcs.each_with_index do |(tail, head), idx|
      circuit.add_arc(tail, head, literals[idx])
    end

    required = [[0, 1], [1, 2], [2, 0]]
    arcs.each_with_index do |arc, idx|
      if required.include?(arc)
        model.add(literals[idx] == 1)
      else
        model.add(literals[idx] == 0)
      end
    end

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    required.each do |arc|
      lit = literals[arcs.index(arc)]
      assert_equal true, solver.value(lit)
    end
  end

  def test_multiple_circuit_constraint_multiple_tours
    model = ORTools::CpModel.new
    arcs = [
      [0, 1], [1, 0],
      [0, 2], [2, 0],
      [0, 3], [3, 0],
      [1, 2], [2, 1], [1, 3], [3, 1], [2, 3], [3, 2],
      [3, 3],
      [4, 4]
    ]
    literals = arcs.map { |tail, head| model.new_bool_var("route_#{tail}_#{head}") }

    routes = model.add_multiple_circuit_constraint
    arcs.each_with_index do |(tail, head), idx|
      routes.add_arc(tail, head, literals[idx])
    end

    # Force two short depot tours: 0->1->0 and 0->2->0. Node 3 should stay unused and loop,
    # node 4 is entirely optional via self-loop.
    must_have = [[0, 1], [1, 0], [0, 2], [2, 0], [3, 3], [4, 4]]
    arcs.each_with_index do |arc, idx|
      if must_have.include?(arc)
        model.add(literals[idx] == 1)
      else
        model.add(literals[idx] == 0)
      end
    end

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal true, solver.value(literals[arcs.index([3, 3])])
  end

  def test_circuit_constraint_with_optional_node
    model = ORTools::CpModel.new
    arcs = [
      [0, 1], [1, 2], [2, 0],
      [3, 3]
    ]
    literals = arcs.map { |tail, head| model.new_bool_var("arc_#{tail}_#{head}") }

    circuit = model.add_circuit_constraint
    arcs.each_with_index do |(tail, head), idx|
      circuit.add_arc(tail, head, literals[idx])
    end

    required = [[0, 1], [1, 2], [2, 0]]
    arcs.each_with_index do |arc, idx|
      model.add(literals[idx] == 1) if required.include?(arc)
    end

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status

    loop_literal = literals[arcs.index([3, 3])]
    assert_equal true, solver.value(loop_literal)
  end

  def test_multiple_circuit_constraint
    model = ORTools::CpModel.new
    arcs = [
      [0, 1], [1, 2], [2, 0],
      [0, 2], [2, 1], [1, 0]
    ]
    literals = arcs.map { |tail, head| model.new_bool_var("route_#{tail}_#{head}") }

    routes = model.add_multiple_circuit_constraint
    arcs.each_with_index do |(tail, head), idx|
      routes.add_arc(tail, head, literals[idx])
    end

    required = [[0, 1], [1, 2], [2, 0]]
    arcs.each_with_index do |arc, idx|
      if required.include?(arc)
        model.add(literals[idx] == 1)
      else
        model.add(literals[idx] == 0)
      end
    end

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    required.each do |arc|
      lit = literals[arcs.index(arc)]
      assert_equal true, solver.value(lit)
    end
  end

  def test_reservoir_constraint_with_optional_event
    model = ORTools::CpModel.new
    reservoir = model.add_reservoir_constraint(0, 3)

    first_fill_time = model.new_int_var(0, 0, "first_fill")
    reservoir.add_event(first_fill_time, 2)

    drain_time = model.new_int_var(1, 1, "drain_time")
    optional = model.new_bool_var("drain_required")
    reservoir.add_optional_event(drain_time, -1, optional)

    second_fill_time = model.new_int_var(2, 2, "second_fill")
    reservoir.add_event(second_fill_time, 2)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal true, solver.value(optional)
  end


  def test_cumulative_constraint_with_optional_interval
    model = ORTools::CpModel.new
    capacity = model.new_constant(3)
    cumulative = model.add_cumulative(capacity)

    start1 = model.new_int_var(0, 0, "start1")
    interval1 = model.new_fixed_size_interval_var(start1, 1, "task1")
    cumulative.add_demand(interval1, 2)

    start2 = model.new_int_var(0, 1, "start2")
    interval2 = model.new_fixed_size_interval_var(start2, 2, "task2")
    cumulative.add_demand(interval2, 2)

    presence = model.new_bool_var("task3_presence")
    model.add(presence == 1)
    start3 = model.new_int_var(1, 1, "start3")
    interval3 = model.new_optional_fixed_size_interval_var(start3, 1, presence, "task3")
    cumulative.add_demand(interval3, 1)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal 1, solver.value(start2)
    assert_equal true, solver.value(presence)
  end

  def test_cumulative_constraint_drops_optional_job
    model = ORTools::CpModel.new
    capacity = model.new_constant(3)
    cumulative = model.add_cumulative(capacity)

    start1 = model.new_int_var(0, 0, "base_start")
    interval1 = model.new_fixed_size_interval_var(start1, 2, "base_task")
    cumulative.add_demand(interval1, 2)

    start2 = model.new_int_var(2, 2, "base_start_2")
    interval2 = model.new_fixed_size_interval_var(start2, 2, "base_task_2")
    cumulative.add_demand(interval2, 2)

    optional_presence = model.new_bool_var("optional_presence")
    optional_start = model.new_int_var(0, 0, "optional_start")
    optional_interval = model.new_optional_fixed_size_interval_var(optional_start, 1, optional_presence, "optional_task")
    cumulative.add_demand(optional_interval, 2)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal false, solver.value(optional_presence)
  end

  def test_no_overlap_2d_constraint
    model = ORTools::CpModel.new

    x1_start = model.new_int_var(0, 0, "x1_start")
    y1_start = model.new_int_var(0, 0, "y1_start")
    rect1_x = model.new_fixed_size_interval_var(x1_start, 2, "rect1_x")
    rect1_y = model.new_fixed_size_interval_var(y1_start, 2, "rect1_y")

    x2_start = model.new_int_var(0, 2, "x2_start")
    y2_start = model.new_int_var(0, 0, "y2_start")
    rect2_x = model.new_fixed_size_interval_var(x2_start, 2, "rect2_x")
    rect2_y = model.new_fixed_size_interval_var(y2_start, 2, "rect2_y")

    constraint = model.add_no_overlap_2d
    constraint.add_rectangle(rect1_x, rect1_y)
    constraint.add_rectangle(rect2_x, rect2_y)

    model.minimize(x2_start)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal 2, solver.value(x2_start)
  end

  def test_no_overlap_2d_optional_rectangles
    model = ORTools::CpModel.new

    base_x = model.new_int_var(0, 0, "base_x")
    base_y = model.new_int_var(0, 0, "base_y")
    base_rect_x = model.new_fixed_size_interval_var(base_x, 2, "base_rect_x")
    base_rect_y = model.new_fixed_size_interval_var(base_y, 2, "base_rect_y")

    optional_start_x = model.new_int_var(0, 4, "opt_x")
    optional_start_y = model.new_int_var(0, 0, "opt_y")
    opt_presence = model.new_bool_var("opt_present")
    opt_rect_x = model.new_optional_fixed_size_interval_var(optional_start_x, 2, opt_presence, "opt_rect_x")
    opt_rect_y = model.new_optional_fixed_size_interval_var(optional_start_y, 2, opt_presence, "opt_rect_y")

    constraint = model.add_no_overlap_2d
    constraint.add_rectangle(base_rect_x, base_rect_y)
    constraint.add_rectangle(opt_rect_x, opt_rect_y)

    model.maximize(opt_presence * 10 - optional_start_x)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal true, solver.value(opt_presence)
    assert_equal 2, solver.value(optional_start_x)
  end

  def test_min_max_and_multiplication_equalities
    model = ORTools::CpModel.new

    x = model.new_int_var(0, 5, "x")
    y = model.new_int_var(0, 5, "y")
    model.add(x == 3)
    model.add(y == 5)

    min_var = model.new_int_var(0, 5, "min")
    max_var = model.new_int_var(0, 5, "max")
    prod = model.new_int_var(0, 25, "prod")

    model.add_min_equality(min_var, [x, y])
    model.add_max_equality(max_var, [x, y])
    model.add_multiplication_equality(prod, [x, y])

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status
    assert_equal 3, solver.value(min_var)
    assert_equal 5, solver.value(max_var)
    assert_equal 15, solver.value(prod)
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

  def test_automaton_rejects_invalid_sequence
    model = ORTools::CpModel.new

    vars = 3.times.map { |i| model.new_int_var(0, 1, "transition_#{i}") }
    transitions = [
      [0, 0, 1],
      [1, 0, 1],
      [1, 1, 2]
    ]

    model.add_automaton(vars, 0, [2], transitions)

    # Force an invalid sequence: first transition is 1, which has no outgoing edge from state 0.
    model.add(vars[0] == 1)

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :infeasible, status
  end
end
