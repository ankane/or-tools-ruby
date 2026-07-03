require_relative "test_helper"

class RoutingGvlTest < Minitest::Test
  def test_matrix_model_releases_gvl_during_solve
    routing, manager = matrix_model
    counter = 0
    ticker = Thread.new { loop { counter += 1 } }

    assignment = routing.solve(time_limit: 1, first_solution_strategy: :path_cheapest_arc, local_search_metaheuristic: :guided_local_search)

    ticker.kill
    assert assignment
    assert_operator assignment.objective_value, :>, 0
    assert_operator counter, :>, 1_000, "expected ticker thread to run while solving"
  ensure
    ticker&.kill
  end

  def test_callback_model_keeps_gvl_and_solves
    routing, manager = callback_model
    counter = 0
    ticker = Thread.new { loop { counter += 1 } }

    assignment = routing.solve(time_limit: 1, first_solution_strategy: :path_cheapest_arc, local_search_metaheuristic: :guided_local_search)

    ticker.kill
    assert assignment
    assert_operator assignment.objective_value, :>, 0
  ensure
    ticker&.kill
  end

  def test_matrix_and_callback_models_agree
    matrix_routing, = matrix_model
    callback_routing, = callback_model

    matrix_assignment = matrix_routing.solve(first_solution_strategy: :path_cheapest_arc)
    callback_assignment = callback_routing.solve(first_solution_strategy: :path_cheapest_arc)

    assert_equal callback_assignment.objective_value, matrix_assignment.objective_value
  end

  def test_solve_from_assignment_releases_gvl
    routing, manager = matrix_model
    routing.close_model
    initial = routing.read_assignment_from_routes([(1...node_count).to_a], true)
    assert initial

    counter = 0
    ticker = Thread.new { loop { counter += 1 } }

    search_parameters = ORTools.default_routing_search_parameters
    search_parameters.time_limit = 1
    search_parameters.local_search_metaheuristic = :guided_local_search
    assignment = routing.solve_from_assignment_with_parameters(initial, search_parameters)

    ticker.kill
    assert assignment
    assert_operator counter, :>, 1_000, "expected ticker thread to run while solving"
  ensure
    ticker&.kill
  end

  private

  def node_count
    30
  end

  def distances
    @distances ||= begin
      rng = Random.new(42)
      Array.new(node_count) do |i|
        Array.new(node_count) { |j| (i == j) ? 0 : rng.rand(100..5000) }
      end
    end
  end

  def matrix_model
    manager = ORTools::RoutingIndexManager.new(node_count, 1, 0)
    routing = ORTools::RoutingModel.new(manager)
    transit = routing.register_transit_matrix(distances)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit)
    [routing, manager]
  end

  def callback_model
    manager = ORTools::RoutingIndexManager.new(node_count, 1, 0)
    routing = ORTools::RoutingModel.new(manager)
    callback = lambda do |from_index, to_index|
      distances[manager.index_to_node(from_index)][manager.index_to_node(to_index)]
    end
    transit = routing.register_transit_callback(callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit)
    [routing, manager]
  end
end
