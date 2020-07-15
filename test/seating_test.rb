require_relative "test_helper"

class SeatingTest < Minitest::Test
  def test_works
    connections = []
    tables = []
    seating = ORTools::Seating.new(connections: connections, tables: tables)
    p seating.assignments
  end
end
