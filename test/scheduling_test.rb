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
    solver.parameters.enumerate_all_solutions = true
    # solver.parameters.linearization_level = 0
    solutions = []
    solution_printer = NursesPartialSolutionPrinter.new(
      shifts, num_nurses, num_days, num_shifts, solutions
    )
    solver.solve(model, solution_printer)

    assert_equal 5184, solution_printer.solution_count
    assert_includes solutions, [[nil, 2, 0, 1], [1, 0, 2, nil], [0, 1, nil, 2]]
    assert_includes solutions, [[nil, 2, 0, 1], [2, 1, 0, nil], [0, 1, nil, 2]]
  end

  def test_job_shop
    # create the model
    model = ORTools::CpModel.new

    jobs_data = [
      [[0, 3], [1, 2], [2, 2]],
      [[0, 2], [2, 1], [1, 4]],
      [[1, 4], [2, 3]]
    ]

    machines_count = 1 + jobs_data.flat_map { |job| job.map { |task| task[0] }  }.max
    all_machines = machines_count.times.to_a

    # computes horizon dynamically as the sum of all durations
    horizon = jobs_data.flat_map { |job| job.map { |task| task[1] }  }.sum

    # creates job intervals and add to the corresponding machine lists
    all_tasks = {}
    machine_to_intervals = Hash.new { |hash, key| hash[key] = [] }

    jobs_data.each_with_index do |job, job_id|
      job.each_with_index do |task, task_id|
        machine = task[0]
        duration = task[1]
        suffix = "_%i_%i" % [job_id, task_id]
        start_var = model.new_int_var(0, horizon, "start" + suffix)
        duration_var = model.new_int_var(duration, duration, "duration" + suffix)
        end_var = model.new_int_var(0, horizon, "end" + suffix)
        interval_var = model.new_interval_var(start_var, duration_var, end_var, "interval" + suffix)
        all_tasks[[job_id, task_id]] = {start: start_var, end: end_var, interval: interval_var}
        machine_to_intervals[machine] << interval_var
      end
    end

    # create and add disjunctive constraints
    all_machines.each do |machine|
      model.add_no_overlap(machine_to_intervals[machine])
    end

    # precedences inside a job
    jobs_data.each_with_index do |job, job_id|
      (job.size - 1).times do |task_id|
        model.add(all_tasks[[job_id, task_id + 1]][:start] >= all_tasks[[job_id, task_id]][:end])
      end
    end

    # makespan objective
    obj_var = model.new_int_var(0, horizon, "makespan")
    model.add_max_equality(obj_var, jobs_data.map.with_index { |job, job_id| all_tasks[[job_id, job.size - 1]][:end] })
    model.minimize(obj_var)

    # solve model
    solver = ORTools::CpSolver.new
    status = solver.solve(model)
    assert_equal :optimal, status

    # create one list of assigned tasks per machine
    assigned_jobs = Hash.new { |hash, key| hash[key] = [] }
    jobs_data.each_with_index do |job, job_id|
      job.each_with_index do |task, task_id|
        machine = task[0]
        assigned_jobs[machine] << {
          start: solver.value(all_tasks[[job_id, task_id]][:start]),
          job: job_id,
          index: task_id,
          duration: task[1]
        }
      end
    end

    # create per machine output lines
    output = String.new("")
    all_machines.each do |machine|
      # sort by starting time
      assigned_jobs[machine].sort_by! { |v| v[:start] }
      sol_line_tasks = "Machine #{machine}: "
      sol_line = "           "

      assigned_jobs[machine].each do |assigned_task|
        name = "job_%i_%i" % [assigned_task[:job], assigned_task[:index]]
        # add spaces to output to align columns
        sol_line_tasks += "%-10s" % name
        start = assigned_task[:start]
        duration = assigned_task[:duration]
        sol_tmp = "[%i,%i]" % [start, start + duration]
        # add spaces to output to align columns
        sol_line += "%-10s" % sol_tmp
      end

      sol_line += "\n"
      sol_line_tasks += "\n"
      output += sol_line_tasks
      output += sol_line
    end

    # finally print the solution found
    # TODO handle multiple possible results
    # assert_equal [[0, 2], [0, 5, 7], [2, 4, 7]], assigned_jobs.map { |_, job| job.map { |task| task[:start] } }
    assert_equal 11, solver.objective_value
  end
end
