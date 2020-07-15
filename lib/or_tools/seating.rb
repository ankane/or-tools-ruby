module ORTools
  class Seating
    attr_reader :assignments, :people

    def initialize(connections:, tables:)
      @people = connections.flat_map { |c| c[:people] }.uniq

      @connection_map = {}
      @people.each do |person|
        @connection_map[person] = {}
      end
      connections.each do |c|
        c[:people].each_with_index do |person, i|
          others = c[:people].dup
          others.delete_at(i)
          others.each do |other|
            @connection_map[person][other] ||= 0
            # currently additive, but could use max
            @connection_map[person][other] += c[:strength]
          end
        end
      end

      @assignments = []
    end

    def connections_for(person)
      @connection_map[person]
    end
  end
end
