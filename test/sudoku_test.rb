require_relative "test_helper"

class SudokuTest < Minitest::Test
  def test_works
    grid = [
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
    sudoku = ORTools::Sudoku.new(grid)
    assert_equal expected, sudoku.solution
  end

  def test_infeasible
    grid = 9.times.map { 9.times.map { 1 } }
    error = assert_raises(ORTools::Error) do
      ORTools::Sudoku.new(grid)
    end
    assert_equal "No solution found", error.message
  end

  def test_invalid_grid_size
    error = assert_raises(ArgumentError) do
      ORTools::Sudoku.new([])
    end
    assert_equal "Grid must be 9x9", error.message
  end

  def test_invalid_grid_values
    grid = 9.times.map { 9.times.map { "a" } }
    error = assert_raises(ArgumentError) do
      ORTools::Sudoku.new(grid)
    end
    assert_equal "Grid must contain values between 0 and 9", error.message
  end

  def test_miracle
    grid = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 1, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 2, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    expected = [
      [4, 8, 3, 7, 2, 6, 1, 5, 9],
      [7, 2, 6, 1, 5, 9, 4, 8, 3],
      [1, 5, 9, 4, 8, 3, 7, 2, 6],
      [8, 3, 7, 2, 6, 1, 5, 9, 4],
      [2, 6, 1, 5, 9, 4, 8, 3, 7],
      [5, 9, 4, 8, 3, 7, 2, 6, 1],
      [3, 7, 2, 6, 1, 5, 9, 4, 8],
      [6, 1, 5, 9, 4, 8, 3, 7, 2],
      [9, 4, 8, 3, 7, 2, 6, 1, 5]
    ]
    sudoku = ORTools::Sudoku.new(grid, anti_knight: true, anti_king: true, non_consecutive: true)
    assert_equal expected, sudoku.solution
  end

  def test_four_digits
    grid = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [3, 8, 4, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 2],
    ]
    expected = [
      [8, 4, 3, 5, 6, 7, 2, 1, 9],
      [2, 7, 5, 9, 1, 3, 8, 4, 6],
      [6, 1, 9, 4, 2, 8, 3, 7, 5],
      [3, 8, 4, 6, 7, 2, 9, 5, 1],
      [7, 2, 6, 1, 5, 9, 4, 8, 3],
      [9, 5, 1, 8, 3, 4, 6, 2, 7],
      [5, 3, 7, 2, 8, 6, 1, 9, 4],
      [4, 6, 2, 7, 9, 1, 5, 3, 8],
      [1, 9, 8, 3, 4, 5, 7, 6, 2]
    ]
    sudoku = ORTools::Sudoku.new(grid, x: true, anti_knight: true, magic_square: true)
    assert_equal expected, sudoku.solution
  end

  # TODO add method for retrieving all solutions
  # def test_multiple_solutions
  #   grid = 9.times.map { 9.times.map { 0 } }
  #   ORTools::Sudoku.new(grid)
  # end
end
