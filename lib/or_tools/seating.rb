module ORTools
  class Seating
    attr_reader :assignments

    def initialize(connections:, tables:)
      @assignments = []
    end
  end
end
