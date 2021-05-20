module ORTools
  class Seating
    attr_reader :assignments, :people, :total_weight

    def initialize(connections:, tables:, min_connections: 1)
      @people = connections.flat_map { |c| c[:people] }.uniq

      @connections_for = {}
      @people.each do |person|
        @connections_for[person] = {}
      end
      connections.each do |c|
        c[:people].each_with_index do |person, i|
          others = c[:people].dup
          others.delete_at(i)
          others.each do |other|
            @connections_for[person][other] ||= 0
            @connections_for[person][other] += c[:weight]
          end
        end
      end

      model = ORTools::CpModel.new
      all_tables = tables.size.times.to_a

      # decision variables
      seats = {}
      all_tables.each do |t|
        people.each do |g|
          seats[[t, g]] = model.new_bool_var("guest %s seats on table %i" % [g, t])
        end
      end

      pairs = people.combination(2)

      colocated = {}
      pairs.each do |g1, g2|
        colocated[[g1, g2]] = model.new_bool_var("guest %s seats with guest %s" % [g1, g2])
      end

      same_table = {}
      pairs.each do |g1, g2|
        all_tables.each do |t|
          same_table[[g1, g2, t]] = model.new_bool_var("guest %s seats with guest %s on table %i" % [g1, g2, t])
        end
      end

      # objective
      objective = []
      pairs.each do |g1, g2|
        weight = @connections_for[g1][g2]
        objective << colocated[[g1, g2]] * weight if weight
      end
      model.maximize(model.sum(objective))

      # everybody seats at one table
      people.each do |g|
        model.add(model.sum(all_tables.map { |t| seats[[t, g]] }) == 1)
      end

      # tables have a max capacity
      all_tables.each do |t|
        model.add(model.sum(@people.map { |g| seats[[t, g]] }) <= tables[t])
      end

      # link colocated with seats
      pairs.each do |g1, g2|
        all_tables.each do |t|
          # link same_table and seats
          model.add_bool_or([seats[[t, g1]].not, seats[[t, g2]].not, same_table[[g1, g2, t]]])
          model.add_implication(same_table[[g1, g2, t]], seats[[t, g1]])
          model.add_implication(same_table[[g1, g2, t]], seats[[t, g2]])
        end

        # link colocated and same_table
        model.add(model.sum(all_tables.map { |t| same_table[[g1, g2, t]] }) == colocated[[g1, g2]])
      end

      # min known neighbors rule
      same_table_by_person = Hash.new { |hash, key| hash[key] = [] }
      same_table.each do |(g1, g2, _t), v|
        next unless @connections_for[g1][g2]
        same_table_by_person[g1] << v
        same_table_by_person[g2] << v
      end
      same_table_by_person.each do |_, vars|
        model.add(model.sum(vars) >= min_connections)
      end

      # solve
      solver = ORTools::CpSolver.new
      status = solver.solve(model)
      raise Error, "No solution found" unless [:feasible, :optimal].include?(status)

      # read solution
      @assignments = {}
      seats.each do |k, v|
        if solver.value(v)
          @assignments[k[1]] = k[0]
        end
      end
      @total_weight = solver.objective_value
    end

    def assigned_tables
      assignments.group_by { |_, v| v }.map { |k, v| [k, v.map(&:first)] }.sort_by(&:first).map(&:last)
    end

    def connections_for(person, same_table: false)
      result = @connections_for[person]
      result = result.select { |k, _| @assignments[k] == @assignments[person] } if same_table
      result
    end
  end
end
