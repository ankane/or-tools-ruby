require_relative "test_helper"

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
      num_shifts_worked = model.sum(all_shifts.flat_map { |s| all_days.map { |d| shifts[[n, d, s]] } })
      model.add(num_shifts_worked > min_shifts_per_nurse)
      model.add(num_shifts_worked <= max_shifts_per_nurse)
    end

    # Creates the solver and solve.
    solver = ORTools::CpSolver.new
    # solver.parameters.linearization_level = 0
    # Display the first five solutions.
    # a_few_solutions = 5.times.to_a
    # solution_printer = NursesPartialSolutionPrinter(shifts, num_nurses,
    #                                                 num_days, num_shifts,
    #                                                 a_few_solutions)
    # solver.SearchForAllSolutions(model, solution_printer)

    # # Statistics.
    # print()
    # print('Statistics')
    # print('  - conflicts       : %i' % solver.NumConflicts())
    # print('  - branches        : %i' % solver.NumBranches())
    # print('  - wall time       : %f s' % solver.WallTime())
    # print('  - solutions found : %i' % solution_printer.solution_count())
  end
end
