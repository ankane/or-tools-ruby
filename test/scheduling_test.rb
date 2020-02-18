require_relative "test_helper"

class NursesPartialSolutionPrinter #< ORTools::CpModel::CpSolverSolutionCallback
  def initialize(shifts, num_nurses, num_days, num_shifts, sols)
    super()
    @shifts = shifts
    @num_nurses = num_nurses
    @num_days = num_days
    @num_shifts = num_shifts
    @solutions = sols
    @solution_count = 0
  end

  def on_solution_callback
    if @solutions.include?(@solution_count)
      puts "Solution #{@solution_count}"
      @num_days.times do |d|
        puts "Day #{d}"
        @num_nurses.times do |n|
          working = false
          @num_shifts.times do |s|
            if value(@shifts[[n, d, s]])
              working = true
              puts "  Nurse %i works shift %i" % [n, s]
            end
          end
          unless working
            puts "  Nurse #{n} does not work"
          end
        end
      end
      puts
    end
    @solution_count += 1
  end

  def solution_count
    @solution_count
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
      num_shifts_worked = model.sum(all_shifts.flat_map { |s| all_days.map { |d| shifts[[n, d, s]] } })
      model.add(num_shifts_worked > min_shifts_per_nurse)
      model.add(num_shifts_worked <= max_shifts_per_nurse)
    end

    solver = ORTools::CpSolver.new
    # solver.parameters.linearization_level = 0
    a_few_solutions = 5.times.to_a
    solution_printer = NursesPartialSolutionPrinter.new(
      shifts, num_nurses, num_days, num_shifts, a_few_solutions
    )
    solver.search_for_all_solutions(model, solution_printer)

    puts
    puts "Statistics"
    puts "  - conflicts       : %i" % solver.num_conflicts
    puts "  - branches        : %i" % solver.num_branches
    puts "  - wall time       : %f s" % solver.wall_time
    puts "  - solutions found : %i" % solution_printer.solution_count
  end
end
