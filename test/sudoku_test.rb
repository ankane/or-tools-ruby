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

  # TODO add method for retrieving all solutions
  # def test_multiple_solutions
  #   grid = 9.times.map { 9.times.map { 0 } }
  #   ORTools::Sudoku.new(grid)
  # end
end
