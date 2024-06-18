require_relative "test_helper"

class SeatingTest < Minitest::Test
  def test_works
    connections = [
      {people: ["A", "B", "C"], weight: 2},
      {people: ["B", "C", "D", "E"], weight: 1}
    ]
    tables = [3, 2]
    seating = ORTools::Seating.new(connections: connections, tables: tables)
    assert_equal ["A", "B", "C", "D", "E"], seating.people
    assert_equal({"B" => 2, "C" => 2}, seating.connections_for("A"))
    assert_equal({"A" => 2, "B" => 3, "D" => 1, "E" => 1}, seating.connections_for("C"))
    assert_equal({"A" => 2, "B" => 3}, seating.connections_for("C", same_table: true))
    expected = {
      "A" => 0,
      "B" => 0,
      "C" => 0,
      "D" => 1,
      "E" => 1
    }
    assert_equal expected, seating.assignments
    # A + B = 2, A + C = 2, B + C = 2, D + E = 1
    assert_equal 8, seating.total_weight
    assert_equal [["A", "B", "C"], ["D", "E"]], seating.assigned_tables
  end

  def test_too_few_seats
    connections = [
      {people: ["A", "B", "C"], weight: 1}
    ]
    tables = [2]
    error = assert_raises(ORTools::Error) do
      ORTools::Seating.new(connections: connections, tables: tables)
    end
    assert_equal "No solution found", error.message
  end

  def test_min_connections
    connections = [
      {people: ["A", "B", "C"], weight: 2},
      {people: ["C", "D"], weight: 1}
    ]
    tables = [3, 3]
    seating = ORTools::Seating.new(connections: connections, tables: tables)
    assert_equal [["A", "B"], ["C", "D"]], seating.assigned_tables.sort
  end

  def test_min_connections_too_high
    connections = [
      {people: ["A", "B", "C"], weight: 2},
      {people: ["C", "D"], weight: 1}
    ]
    tables = [3, 3]
    error = assert_raises(ORTools::Error) do
      ORTools::Seating.new(connections: connections, tables: tables, min_connections: 2)
    end
    assert_equal "No solution found", error.message
  end

  def test_negative_weight
    connections = [
      {people: ["A", "B", "C", "D"], weight: 2},
      {people: ["A", "D"], weight: -1}
    ]
    tables = [3, 3]
    seating = ORTools::Seating.new(connections: connections, tables: tables)
    assert_equal [2, 2], seating.assigned_tables.map(&:size)
    refute_includes ["A", "D"], seating.assigned_tables
  end
end
