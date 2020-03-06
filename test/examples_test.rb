require_relative "test_helper"

class ORToolsTest < Minitest::Test
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
    assert_equal :feasible, status

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

    assert_equal 3213, possible_tables.size

    final_tables = possible_tables.select { |table| x[table].solution_value == 1 }
    expected = [["M", "N"], ["E", "F", "G"], ["A", "B", "C", "D"], ["I", "J", "K", "L"], ["O", "P", "Q", "R"]]
    assert_equal expected, final_tables
  end
end
