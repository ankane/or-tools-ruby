require_relative "test_helper"

class SeatingTest < Minitest::Test
  def test_works
    connections = [
      {people: ["A", "B", "C"], strength: 2},
      {people: ["B", "C", "D", "E"], strength: 1}
    ]
    tables = [3, 2]
    seating = ORTools::Seating.new(connections: connections, tables: tables)
    assert_equal ["A", "B", "C", "D", "E"], seating.people
    assert_equal({"B" => 2, "C" => 2}, seating.connections_for("A"))
    assert_equal({"A" => 2, "B" => 3, "D" => 1, "E" => 1}, seating.connections_for("C"))
    expected = [
      {person: "A", table: 0},
      {person: "B", table: 0},
      {person: "C", table: 0},
      {person: "D", table: 1},
      {person: "E", table: 1}
    ]
    p seating.assignments
    # assert_equal expected, seating.assignments
  end
end
