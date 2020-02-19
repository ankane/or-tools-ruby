require_relative "test_helper"

class NursesPartialSolutionPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(shifts, num_nurses, num_days, num_shifts, solutions)
    super()
    @shifts = shifts
    @num_nurses = num_nurses
    @num_days = num_days
    @num_shifts = num_shifts
    @solutions = solutions
    @solution_count = 0
  end

  def on_solution_callback
    if @solution_count < 2
      solution = []
      @num_days.times do |d|
        day = []
        @num_nurses.times do |n|
          working = false
          @num_shifts.times do |s|
            if value(@shifts[[n, d, s]])
              working = true
              day[n] = s
            end
          end
          unless working
            day[n] = nil
          end
        end
        solution << day
      end
      @solutions << solution
    end
    @solution_count += 1
  end
end

class SchedulingTest < Minitest::Test
  # https://developers.google.com/optimization/scheduling/employee_scheduling
  def test_employee_scheduling
    num_nurses = 4
    num_shifts = 3
    num_days = 3
    all_nurses = num_nurses.times.to_a
    all_shifts = num_shifts.times.to_a
    all_days = num_days.times.to_a

    model = ORTools::CpModel.new

    shifts = {}
    all_nurses.each do |n|
      all_days.each do |d|
        all_shifts.each do |s|
          shifts[[n, d, s]] = model.new_bool_var("shift_n%id%is%i" % [n, d, s])
        end
      end
    end

    all_days.each do |d|
      all_shifts.each do |s|
        model.add(model.sum(all_nurses.map { |n| shifts[[n, d, s]] }) == 1)
      end
    end

    all_nurses.each do |n|
      all_days.each do |d|
        model.add(model.sum(all_shifts.map { |s| shifts[[n, d, s]] }) <= 1)
      end
    end

    min_shifts_per_nurse = (num_shifts * num_days) / num_nurses
    max_shifts_per_nurse = min_shifts_per_nurse + 1
    all_nurses.each do |n|
      num_shifts_worked = model.sum(all_days.flat_map { |d| all_shifts.map { |s| shifts[[n, d, s]] } })
      model.add(num_shifts_worked >= min_shifts_per_nurse)
      model.add(num_shifts_worked <= max_shifts_per_nurse)
    end

    solver = ORTools::CpSolver.new
    # solver.parameters.linearization_level = 0
    solutions = []
    solution_printer = NursesPartialSolutionPrinter.new(
      shifts, num_nurses, num_days, num_shifts, solutions
    )
    solver.search_for_all_solutions(model, solution_printer)

    assert_equal 5184, solution_printer.solution_count

    skip if ENV["TRAVIS"]

    expected = [
      [[nil, 2, 0, 1], [1, 0, 2, nil], [0, 1, nil, 2]],
      [[nil, 2, 0, 1], [2, 1, 0, nil], [0, 1, nil, 2]]
    ]
    assert_equal expected, solutions

    assert_equal 895, solver.num_conflicts
    assert_equal 63883, solver.num_branches
  end
end
