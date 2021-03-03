require_relative "test_helper"

class WeddingChartPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :num_solutions

  def initialize(seats, names, num_tables, num_guests)
    super()
    @num_solutions = 0
    @start_time = Time.now
    @seats = seats
    @names = names
    @num_tables = num_tables
    @num_guests = num_guests
  end

  def on_solution_callback
    # current_time = Time.now
    # puts "Solution %i, time = %f s, objective = %i" % [@num_solutions, current_time - @start_time, objective_value]
    @num_solutions += 1

    @num_tables.times do |t|
      # puts "Table %d: " % t
      @num_guests.times do |g|
        if value(@seats[[t, g]])
          # puts "  " + @names[g]
        end
      end
    end
  end
end

class ExamplesTest < Minitest::Test
  def test_sudoku
    model = ORTools::CpModel.new

    cell_size = 3
    line_size = cell_size**2
    line = (0...line_size).to_a
    cell = (0...cell_size).to_a

    initial_grid = [
      [0, 6, 0, 0, 5, 0, 0, 2, 0],
      [0, 0, 0, 3, 0, 0, 0, 9, 0],
      [7, 0, 0, 6, 0, 0, 0, 1, 0],
      [0, 0, 6, 0, 3, 0, 4, 0, 0],
      [0, 0, 4, 0, 7, 0, 1, 0, 0],
      [0, 0, 5, 0, 9, 0, 8, 0, 0],
      [0, 4, 0, 0, 0, 1, 0, 0, 6],
      [0, 3, 0, 0, 0, 8, 0, 0, 0],
      [0, 2, 0, 0, 4, 0, 0, 5, 0]
    ]

    grid = {}
    line.each do |i|
      line.each do |j|
        grid[[i, j]] = model.new_int_var(1, line_size, "grid %i %i" % [i, j])
      end
    end

    line.each do |i|
      model.add_all_different(line.map { |j| grid[[i, j]] })
    end

    line.each do |j|
      model.add_all_different(line.map { |i| grid[[i, j]] })
    end

    cell.each do |i|
      cell.each do |j|
        one_cell = []
        cell.each do |di|
          cell.each do |dj|
            one_cell << grid[[i * cell_size + di, j * cell_size + dj]]
          end
        end
        model.add_all_different(one_cell)
      end
    end

    line.each do |i|
      line.each do |j|
        if initial_grid[i][j] != 0
          model.add(grid[[i, j]] == initial_grid[i][j])
        end
      end
    end

    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status

    expected = [
      [8, 6, 1, 4, 5, 9, 7, 2, 3],
      [4, 5, 2, 3, 1, 7, 6, 9, 8],
      [7, 9, 3, 6, 8, 2, 5, 1, 4],
      [2, 1, 6, 8, 3, 5, 4, 7, 9],
      [9, 8, 4, 2, 7, 6, 1, 3, 5],
      [3, 7, 5, 1, 9, 4, 8, 6, 2],
      [5, 4, 7, 9, 2, 1, 3, 8, 6],
      [1, 3, 9, 5, 6, 8, 2, 4, 7],
      [6, 2, 8, 7, 4, 3, 9, 5, 1]
    ]

    actual = []
    line.each do |i|
      actual << line.map { |j| solver.value(grid[[i, j]]) }
    end

    assert_equal expected, actual
  end

  # https://pythonhosted.org/PuLP/CaseStudies/a_set_partitioning_problem.html
  def test_set_partitioning
    # A set partitioning model of a wedding seating problem
    # Authors: Stuart Mitchell 2009

    max_tables = 5
    max_table_size = 4
    guests = %w(A B C D E F G I J K L M N O P Q R)

    # Find the happiness of the table
    # by calculating the maximum distance between the letters
    def happiness(table)
      (table[0].ord - table[-1].ord).abs
    end

    # create list of all possible tables
    possible_tables = []
    (1..max_table_size).each do |i|
      possible_tables += guests.combination(i).to_a
    end

    solver = ORTools::Solver.new("Wedding Seating Model", :cbc)

    # create a binary variable to state that a table setting is used
    x = {}
    possible_tables.each do |table|
      x[table] = solver.int_var(0, 1, "table #{table.join(", ")}")
    end

    solver.minimize(solver.sum(possible_tables.map { |table| x[table] * happiness(table) }))

    # specify the maximum number of tables
    solver.add(solver.sum(x.values) <= max_tables)

    # a guest must seated at one and only one table
    guests.each do |guest|
      tables_with_guest = possible_tables.select { |table| table.include?(guest) }
      solver.add(solver.sum(tables_with_guest.map { |table| x[table] }) == 1)
    end

    status = solver.solve
    assert_equal :optimal, status

    assert_equal 3213, possible_tables.size

    final_tables = possible_tables.select { |table| x[table].solution_value == 1 }
    expected = [["M", "N"], ["E", "F", "G"], ["A", "B", "C", "D"], ["I", "J", "K", "L"], ["O", "P", "Q", "R"]]
    assert_equal expected, final_tables
  end

  # https://github.com/google/or-tools/blob/stable/examples/python/wedding_optimal_chart_sat.py
  def test_wedding
    # Easy problem (from the paper)
    # num_tables = 2
    # table_capacity = 10
    # min_known_neighbors = 1

    # Slightly harder problem (also from the paper)
    num_tables = 5
    table_capacity = 4
    min_known_neighbors = 1

    # Connection matrix: who knows who, and how strong
    # is the relation
    c = [
      [1, 50, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [50, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 50, 1, 1, 1, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 50, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 50, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 50, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 50, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 50, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 10, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 50, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1]
    ]

    # Names of the guests. B: Bride side, G: Groom side
    names = [
      "Deb (B)", "John (B)", "Martha (B)", "Travis (B)", "Allan (B)",
      "Lois (B)", "Jayne (B)", "Brad (B)", "Abby (B)", "Mary Helen (G)",
      "Lee (G)", "Annika (G)", "Carl (G)", "Colin (G)", "Shirley (G)",
      "DeAnn (G)", "Lori (G)"
    ]

    num_guests = c.size

    all_tables = num_tables.times.to_a
    all_guests = num_guests.times.to_a

    # create the cp model
    model = ORTools::CpModel.new

    # decision variables
    seats = {}
    all_tables.each do |t|
      all_guests.each do |g|
        seats[[t, g]] = model.new_bool_var("guest %i seats on table %i" % [g, t])
      end
    end

    pairs = all_guests.combination(2)

    colocated = {}
    pairs.each do |g1, g2|
      colocated[[g1, g2]] = model.new_bool_var("guest %i seats with guest %i" % [g1, g2])
    end

    same_table = {}
    pairs.each do |g1, g2|
      all_tables.each do |t|
        same_table[[g1, g2, t]] = model.new_bool_var("guest %i seats with guest %i on table %i" % [g1, g2, t])
      end
    end

    # Objective
    model.maximize(model.sum((num_guests - 1).times.flat_map { |g1| (g1 + 1).upto(num_guests - 1).select { |g2| c[g1][g2] > 0 }.map { |g2| colocated[[g1, g2]] * c[g1][g2] } }))

    #
    # Constraints
    #

    # Everybody seats at one table.
    all_guests.each do |g|
      model.add(model.sum(all_tables.map { |t| seats[[t, g]] }) == 1)
    end

    # Tables have a max capacity.
    all_tables.each do |t|
      model.add(model.sum(all_guests.map { |g| seats[[t, g]] }) <= table_capacity)
    end

    # Link colocated with seats
    pairs.each do |g1, g2|
      all_tables.each do |t|
        # Link same_table and seats.
        model.add_bool_or([seats[[t, g1]].not, seats[[t, g2]].not, same_table[[g1, g2, t]]])
        model.add_implication(same_table[[g1, g2, t]], seats[[t, g1]])
        model.add_implication(same_table[[g1, g2, t]], seats[[t, g2]])
      end

      # Link colocated and same_table.
      model.add(model.sum(all_tables.map { |t| same_table[[g1, g2, t]] }) == colocated[[g1, g2]])
    end

    # Min known neighbors rule.
    all_guests.each do |g|
      model.add(
        model.sum(
          (g + 1).upto(num_guests - 1).
          select { |g2| c[g][g2] > 0 }.
          product(all_tables).
          map { |g2, t| same_table[[g, g2, t]] }
        ) +
        model.sum(
          g.times.
          select { |g1| c[g1][g] > 0 }.
          product(all_tables).
          map { |g1, t| same_table[[g1, g, t]] }
        ) >= min_known_neighbors
      )
    end

    # Symmetry breaking. First guest seats on the first table.
    model.add(seats[[0, 0]] == 1)

    ### Solve model
    solver = ORTools::CpSolver.new
    solution_printer = WeddingChartPrinter.new(seats, names, num_tables, num_guests)
    solver.solve_with_solution_callback(model, solution_printer)
    assert_equal 276, solver.objective_value
  end
end
