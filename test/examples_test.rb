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
end
