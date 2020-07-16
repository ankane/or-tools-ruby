module ORTools
  class Seating
    attr_reader :assignments, :people

    def initialize(connections:, tables:)
      @people = connections.flat_map { |c| c[:people] }.uniq

      @connection_for = {}
      @people.each do |person|
        @connection_for[person] = {}
      end
      connections.each do |c|
        c[:people].each_with_index do |person, i|
          others = c[:people].dup
          others.delete_at(i)
          others.each do |other|
            @connection_for[person][other] ||= 0
            # currently additive, but could use max
            @connection_for[person][other] += c[:weight]
          end
        end
      end

      @assignments = []
    end

    def connections_for(person)
      @connection_for[person]
    end
  end
end
