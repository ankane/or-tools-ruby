module ORTools
  class BasicScheduler
    attr_reader :assignments, :assigned_hours

    # for time blocks (shifts and availability)
    # could also use time range (starts_at..ends_at) or starts_at + duration
    # keep current format for now for flexibility
    def initialize(people:, shifts:)
      @shifts = shifts

      model = ORTools::CpModel.new

      # create variables
      # a person must be available for the entire shift to be considered for it
      vars = []
      shifts.each_with_index do |shift, i|
        people.each_with_index do |person, j|
          if person[:availability].any? { |a| a[:starts_at] <= shift[:starts_at] && a[:ends_at] >= shift[:ends_at] }
            vars << {shift: i, person: j, var: model.new_bool_var("{shift: #{i}, person: #{j}}")}
          end
        end
      end

      vars_by_shift = vars.group_by { |v| v[:shift] }
      vars_by_person = vars.group_by { |v| v[:person] }

      # one person per shift
      vars_by_shift.each do |j, vs|
        model.add(model.sum(vs.map { |v| v[:var] }) <= 1)
      end

      # one shift per day per person
      # in future, may also want to add option to ensure assigned shifts are N hours apart
      vars_by_person.each do |j, vs|
        vs.group_by { |v| shift_dates[v[:shift]] }.each do |_, vs2|
          model.add(model.sum(vs2.map { |v| v[:var] }) <= 1)
        end
      end

      # max hours per person
      # use seconds since model needs integers
      vars_by_person.each do |j, vs|
        max_hours = people[j][:max_hours]
        if max_hours
          model.add(model.sum(vs.map { |v| v[:var] * shift_duration[v[:shift]] }) <= max_hours * 3600)
        end
      end

      # maximize hours assigned
      # could also include distance from max hours
      model.maximize(model.sum(vars.map { |v| v[:var] * shift_duration[v[:shift]] }))

      # solve
      solver = ORTools::CpSolver.new
      status = solver.solve(model)
      raise Error, "No solution found" unless [:feasible, :optimal].include?(status)

      # read solution
      @assignments = []
      vars.each do |v|
        if solver.value(v[:var])
          @assignments << {
            person: v[:person],
            shift: v[:shift]
          }
        end
      end
      # can calculate manually if objective changes
      @assigned_hours = solver.objective_value / 3600.0
    end

    def total_hours
      @total_hours ||= shift_duration.sum / 3600.0
    end

    private

    def shift_duration
      @shift_duration ||= @shifts.map { |s| (s[:ends_at] - s[:starts_at]).round }
    end

    def shift_dates
      @shift_dates ||= @shifts.map { |s| s[:starts_at].to_date }
    end
  end
end
