module ORTools
  class Sudoku
    attr_reader :solution

    def initialize(initial_grid, x: false)
      raise ArgumentError, "Grid must be 9x9" unless initial_grid.size == 9 && initial_grid.all? { |r| r.size == 9 }
      raise ArgumentError, "Grid must contain values between 0 and 9" unless initial_grid.flatten(1).all? { |v| (0..9).include?(v) }

      model = ORTools::CpModel.new

      cell_size = 3
      line_size = cell_size**2
      line = (0...line_size).to_a
      cell = (0...cell_size).to_a

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

      if x
        model.add_all_different(9.times.map { |i| grid[[i, i]] })
        model.add_all_different(9.times.map { |i| grid[[i, 8 - i]] })
      end

      solver = ORTools::CpSolver.new
      status = solver.solve(model)
      raise Error, "No solution found" unless [:feasible, :optimal].include?(status)

      solution = []
      line.each do |i|
        solution << line.map { |j| solver.value(grid[[i, j]]) }
      end
      @solution = solution
    end
  end
end
