require_relative "test_helper"

class ShiftSchedulingSatTest < Minitest::Test
  def test_shift_scheduling_sat
    num_employees = 8
    num_weeks = 3
    shifts = %w[O M A N]

    # Fixed assignment: (employee, shift, day).
    # This fixes the first 2 days of the schedule.
    fixed_assignments = [
      [0, 0, 0],
      [1, 0, 0],
      [2, 1, 0],
      [3, 1, 0],
      [4, 2, 0],
      [5, 2, 0],
      [6, 2, 3],
      [7, 3, 0],
      [0, 1, 1],
      [1, 1, 1],
      [2, 2, 1],
      [3, 2, 1],
      [4, 2, 1],
      [5, 0, 1],
      [6, 0, 1],
      [7, 3, 1]
    ]

    # Request: (employee, shift, day, weight)
    # A negative weight indicates that the employee desire this assignment.
    requests = [
      # Employee 3 wants the first Saturday off.
      [3, 0, 5, -2],
      # Employee 5 wants a night shift on the second Thursday.
      [5, 3, 10, -2],
      # Employee 2 does not want a night shift on the third Friday.
      [2, 3, 4, 4]
    ]

    # Shift constraints on continuous sequence :
    #     (shift, hard_min, soft_min, min_penalty,
    #             soft_max, hard_max, max_penalty)
    shift_constraints = [
      # One or two consecutive days of rest, this is a hard constraint.
      [0, 1, 1, 0, 2, 2, 0],
      # betweem 2 and 3 consecutive days of night shifts, 1 and 4 are
      # possible but penalized.
      [3, 1, 2, 20, 3, 4, 5]
    ]

    # Weekly sum constraints on shifts days:
    #     (shift, hard_min, soft_min, min_penalty,
    #             soft_max, hard_max, max_penalty)
    weekly_sum_constraints = [
      # Constraints on rests per week.
      [0, 1, 2, 7, 2, 3, 4],
      # At least 1 night shift per week (penalized). At most 4 (hard).
      [3, 0, 1, 3, 4, 4, 0]
    ]

    # Penalized transitions:
    #     (previous_shift, next_shift, penalty (0 means forbidden))
    penalized_transitions = [
      # Afternoon to night has a penalty of 4.
      [2, 3, 4],
      # Night to morning is forbidden.
      [3, 1, 0]
    ]

    # daily demands for work shifts (morning, afternon, night) for each day
    # of the week starting on Monday.
    weekly_cover_demands = [
      [2, 3, 1],  # Monday
      [2, 3, 1],  # Tuesday
      [2, 2, 2],  # Wednesday
      [2, 3, 1],  # Thursday
      [2, 2, 2],  # Friday
      [1, 2, 3],  # Saturday
      [1, 3, 1] # Sunday
    ]

    # Penalty for exceeding the cover constraint per shift type.
    excess_cover_penalties = [2, 2, 5]

    num_days = num_weeks * 7
    num_shifts = shifts.size

    model = ORTools::CpModel.new

    work = {}
    num_employees.times do |e|
      num_shifts.times do |s|
        num_days.times do |d|
          work[[e, s, d]] = model.new_bool_var(format('work%i_%i_%i', e, s, d))
        end
      end
    end

    # Linear terms of the objective in a minimization context.
    obj_int_vars = []
    obj_int_coeffs = []
    obj_bool_vars = []
    obj_bool_coeffs = []

    # Exactly one shift per day.
    num_employees.times do |e|
      num_days.times do |d|
        model.add(model.sum(num_shifts.times.map { |s| work[[e, s, d]] }) == 1)
      end
    end

    # Fixed assignments.
    fixed_assignments.each do |e, s, d|
      model.add(work[[e, s, d]] == 1)
    end

    # Employee requests
    requests.each do |e, s, d, w|
      obj_bool_vars << work[[e, s, d]]
      obj_bool_coeffs << w
    end

    # Shift constraints
    shift_constraints.each do |shift, hard_min, soft_min, min_cost, soft_max, hard_max, max_cost|
      num_employees.times do |e|
        works = num_days.times.map { |d| work[[e, shift, d]] }
        variables, coeffs = add_soft_sequence_constraint(
          model, works, hard_min, soft_min, min_cost, soft_max, hard_max,
          max_cost,
          format('shift_constraint(employee %i, shift %i)', e, shift)
        )
        obj_bool_vars += variables
        obj_bool_coeffs += coeffs
      end
    end

    # Weekly sum constraints
    weekly_sum_constraints.each do |shift, hard_min, soft_min, min_cost, soft_max, hard_max, max_cost|
      num_employees.times do |e|
        num_weeks.times do |w|
          works = 7.times.map { |d| work[[e, shift, d + w * 7]] }
          variables, coeffs = add_soft_sum_constraint(
            model, works, hard_min, soft_min, min_cost, soft_max,
            hard_max, max_cost,
            format('weekly_sum_constraint(employee %i, shift %i, week %i)', e, shift, w)
          )
          obj_int_vars += variables
          obj_int_coeffs += coeffs
        end
      end
    end

    # Penalized transitions
    penalized_transitions.each do |previous_shift, next_shift, cost|
      num_employees.times do |e|
        (num_days - 1).times do |d|
          transition = [
            work[[e, previous_shift, d]].not, work[[e, next_shift, d + 1]].not
          ]
          if cost.zero?
            model.add_bool_or(transition)
          else
            trans_var = model.new_bool_var(format('transition (employee=%i, day=%i)', e, d))
            transition << trans_var
            model.add_bool_or(transition)
            obj_bool_vars << trans_var
            obj_bool_coeffs << cost
          end
        end
      end
    end

    # Cover constraints
    (1...num_shifts).each do |s|
      num_weeks.times do |w|
        7.times do |d|
          works = num_employees.times.map { |e| work[[e, s, w * 7 + d]] }
          # Ignore Off shift.
          min_demand = weekly_cover_demands[d][s - 1]
          worked = model.new_int_var(min_demand, num_employees, '')
          model.add(worked == model.sum(works))
          over_penalty = excess_cover_penalties[s - 1]
          next unless over_penalty.positive?

          name = format('excess_demand(shift=%i, week=%i, day=%i)', s, w, d)
          excess = model.new_int_var(0, num_employees - min_demand, name)
          model.add(excess == worked - min_demand)
          obj_int_vars << excess
          obj_int_coeffs << over_penalty
        end
      end
    end

    # Objective
    model.minimize(
      model.sum(obj_bool_vars.size.times.map { |i| obj_bool_vars[i] * obj_bool_coeffs[i] }) +
      model.sum(obj_int_vars.size.times.map { |i| obj_int_vars[i] * obj_int_coeffs[i] })
    )

    # Solve the model.
    solver = ORTools::CpSolver.new
    solver.parameters.max_time_in_seconds = 1
    # solution_printer = ORTools::ObjectiveSolutionPrinter.new
    # status = solver.solve_with_solution_callback(model, solution_printer)
    status = solver.solve(model)

    assert_equal :feasible, status
    assert_operator solver.objective_value, :<=, 253

    _assignments = num_employees.times.map do |e|
      num_days.times.map do |d|
        num_shifts.times.detect do |s|
          break shifts[s] if solver.value(work[[e, s, d]])
        end
      end
    end

    # different based on solution found
    # assert_equal [
    #   %w[O M M M N N O M N N A A O O A O A O A M N],
    #   %w[O M A O N N N N A A M O O A A A M N N A O],
    #   %w[M A O A M A A M A A O N N A M N N A O O A],
    #   %w[M A O M N N O A M M N O M O O A O A M N A],
    #   %w[A A M O A O A A O M M N N O O A M M N N O],
    #   %w[A O N N A M O N N O A A A A M M A O M N O],
    #   %w[A O A A O A A A M N O M A M A M N A O O M],
    #   %w[N N N A M O M O A O A M N N N O O M A A A]
    # ], assignments
  end

  private

  def add_soft_sequence_constraint(model, works, hard_min, soft_min, min_cost, soft_max, hard_max, max_cost, prefix)
    cost_literals = []
    cost_coefficients = []

    # Forbid sequences that are too short.
    (1...hard_min).each do |length|
      (works.size - length - 1).times do |start|
        model.add_bool_or(negated_bounded_span(works, start, length))
      end
    end

    # Penalize sequences that are below the soft limit.
    if min_cost.positive?
      (hard_min...soft_min).each do |length|
        (works.size - length - 1).times do |start|
          span = negated_bounded_span(works, start, length)
          name = format(': under_span(start=%i, length=%i)', start, length)
          lit = model.new_bool_var(prefix + name)
          span << lit
          model.add_bool_or(span)
          cost_literals << lit
          # We filter exactly the sequence with a short length.
          # The penalty is proportional to the delta with soft_min.
          cost_coefficients << (min_cost * (soft_min - length))
        end
      end
    end

    # Penalize sequences that are above the soft limit.
    if max_cost.positive?
      ((soft_max + 1)...(hard_max + 1)).each do |length|
        (works.size - length - 1).times do |start|
          span = negated_bounded_span(works, start, length)
          name = format(': over_span(start=%i, length=%i)', start, length)
          lit = model.new_bool_var(prefix + name)
          span << lit
          model.add_bool_or(span)
          cost_literals << lit
          # Cost paid is max_cost * excess length.
          cost_coefficients << (max_cost * (length - soft_max))
        end
      end
    end

    # Just forbid any sequence of true variables with length hard_max + 1
    (works.size - hard_max - 1).times do |start|
      model.add_bool_or(
        (start...(start + hard_max + 1)).map { |i| works[i].not }
      )
    end

    [cost_literals, cost_coefficients]
  end

  def add_soft_sum_constraint(model, works, hard_min, soft_min, min_cost, soft_max, hard_max, max_cost, prefix)
    cost_variables = []
    cost_coefficients = []
    sum_var = model.new_int_var(hard_min, hard_max, '')

    # This adds the hard constraints on the sum.
    model.add(sum_var == model.sum(works))

    # Penalize sums below the soft_min target.
    if soft_min > hard_min && min_cost.positive?
      delta = model.new_int_var(-works.size, works.size, '')
      model.add(delta + sum_var == soft_min)
      # TODO(user): Compare efficiency with only excess >= soft_min - sum_var.
      excess = model.new_int_var(0, 7, "#{prefix}: under_sum")
      model.add_max_equality(excess, [delta, model.new_constant(0)])
      cost_variables << excess
      cost_coefficients << min_cost
    end

    # Penalize sums above the soft_max target.
    if soft_max < hard_max && max_cost.positive?
      delta = model.new_int_var(-7, 7, '')
      model.add(delta == sum_var - soft_max)
      excess = model.new_int_var(0, 7, "#{prefix}: over_sum")
      model.add_max_equality(excess, [delta, model.new_constant(0)])
      cost_variables << excess
      cost_coefficients << max_cost
    end

    [cost_variables, cost_coefficients]
  end

  def negated_bounded_span(works, start, length)
    sequence = []
    # Left border (start of works, or works[start - 1])
    sequence << works[start - 1] if start.positive?
    length.times do |i|
      sequence << works[start + i].not
    end
    # Right border (end of works or works[start + length])
    sequence << works[start + length] if start + length < works.size
    sequence
  end
end
