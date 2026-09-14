require_relative "test_helper"

class RoutingConstraintsTest < Minitest::Test
  def test_no_extra_constraints
    build_routing
    solve

    assert_equal :success, @routing.status
    assert_equal [0, 2, 1, 0], route
  end

  def test_var_less_than_or_equal_var
    build_routing
    @routing.solver.add(@distance_dimension.cumul_var(@manager.node_to_index(1)) <= @distance_dimension.cumul_var(@manager.node_to_index(2)))
    solve

    assert_equal :success, @routing.status
    assert_equal [0, 1, 2, 0], route
  end

  def test_var_less_than_or_equal_const
    build_routing
    @routing.solver.add(@distance_dimension.cumul_var(@manager.node_to_index(1)) <= 2455)
    solve

    assert_equal :success, @routing.status
    assert_equal [0, 1, 2, 0], route
  end

  def test_var_equal_const
    build_routing
    @routing.solver.add(@distance_dimension.cumul_var(@manager.node_to_index(1)) == 2451)
    solve

    assert_equal :success, @routing.status
    assert_equal [0, 1, 2, 0], route
  end

  def test_var_equal_const_failure
    build_routing
    @routing.solver.add(@distance_dimension.cumul_var(@manager.node_to_index(1)) == 2455)
    solve

    assert_equal :fail, @routing.status
  end

  private

  def build_routing
    @manager = ORTools::RoutingIndexManager.new(3, 1, 0)
    @routing = ORTools::RoutingModel.new(@manager)
    transit_callback_index = @routing.register_transit_matrix([
      [0, 2451, 731],
      [2451, 0, 1745],
      [731, 1745, 0],
    ])
    @routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
    @routing.add_dimension(transit_callback_index, 0, 10000, true, "Distance")
    @distance_dimension = @routing.mutable_dimension("Distance")
  end

  def solve
    @solution = @routing.solve(first_solution_strategy: :path_cheapest_arc)
  end

  def route
    route = []
    index = @routing.start(0)
    while !@routing.end?(index)
      route << @manager.index_to_node(index)
      index = @solution.value(@routing.next_var(index))
    end
    route << @manager.index_to_node(index)
    route
  end
end
