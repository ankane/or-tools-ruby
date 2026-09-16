require_relative "test_helper"

class RoutingGvlTest < Minitest::Test
  NODE_COUNT = 10_000
  VEHICLE_COUNT = 4

  def test_close_model_releases_the_gvl_without_ruby_callbacks
    skip if valgrind?

    routing, = build_setup_model

    assert_peer_runs_during("_close_model") { routing.close_model }
  end

  def test_read_assignment_from_routes_releases_the_gvl_without_ruby_callbacks
    skip if valgrind?

    routing, = build_setup_model
    routes = [(1...NODE_COUNT).to_a, [], [], []]
    routing.close_model

    assignment = assert_peer_runs_during("_read_assignment_from_routes") do
      routing.read_assignment_from_routes(routes, true)
    end

    assert_instance_of ORTools::Assignment, assignment
  end

  def test_setup_calls_use_the_solve_callback_gate
    manager = ORTools::RoutingIndexManager.new(2, 1, 0)
    routing = ORTools::RoutingModel.new(manager)
    routes = [[1]]
    routing.define_singleton_method(:_close_model) { |release_gvl| release_gvl }
    routing.define_singleton_method(:_read_assignment_from_routes) do |
      actual_routes,
      ignore_inactive_indices,
      release_gvl
    |
      [actual_routes, ignore_inactive_indices, release_gvl]
    end
    routing.singleton_class.send(
      :private,
      :_close_model,
      :_read_assignment_from_routes
    )

    assert_equal true, routing.close_model
    assert_equal [routes, true, true],
      routing.read_assignment_from_routes(routes, true)

    routing.register_unary_transit_callback(->(_index) { 1 })

    assert_equal false, routing.close_model
    assert_equal [routes, true, false],
      routing.read_assignment_from_routes(routes, true)
  end

  def test_native_callback_and_setup_methods_are_private
    routing = ORTools::RoutingModel.new(
      ORTools::RoutingIndexManager.new(2, 1, 0)
    )

    native_methods = [
      :_register_unary_transit_callback,
      :_register_transit_callback,
      :_solve_with_parameters,
      :_solve_from_assignment_with_parameters,
      :_close_model,
      :_read_assignment_from_routes
    ]
    native_methods.each do |method|
      refute routing.respond_to?(method)
      assert routing.respond_to?(method, true)
    end
    assert_raises(NoMethodError) do
      routing._register_unary_transit_callback(->(_index) { 1 })
    end
    assert_raises(NoMethodError) do
      routing._register_transit_callback(->(_from_index, _to_index) { 1 })
    end
    assert_raises(NoMethodError) { routing._solve_with_parameters }
    assert_raises(NoMethodError) do
      routing._solve_from_assignment_with_parameters
    end
    assert_raises(NoMethodError) { routing._close_model(true) }
    assert_raises(NoMethodError) do
      routing._read_assignment_from_routes([[1]], true, true)
    end
  end

  def test_callback_exceptions_are_preserved_during_setup_calls
    routing, = build_callback_model do |_from_index, _to_index|
      raise "close callback failed"
    end

    error = assert_raises(RuntimeError) { routing.close_model }
    assert_equal "close callback failed", error.message

    routing, = build_callback_model do |_from_index, _to_index|
      raise "read callback failed"
    end

    error = assert_raises(RuntimeError) do
      routing.read_assignment_from_routes([[1, 2]], true)
    end
    assert_equal "read callback failed", error.message
  end

  def test_setup_results_match_with_and_without_ruby_callbacks
    matrix_routing, matrix_manager = build_result_model
    callback_routing, callback_manager = build_result_model(callback: true)

    assert_nil matrix_routing.close_model
    assert_nil callback_routing.close_model

    matrix_assignment = matrix_routing.read_assignment_from_routes([[1, 2]], true)
    callback_assignment = callback_routing.read_assignment_from_routes([[1, 2]], true)

    assert_equal 16, matrix_assignment.objective_value
    assert_equal matrix_assignment.objective_value,
      callback_assignment.objective_value
    assert_equal [0, 1, 2, 0],
      assignment_route(matrix_routing, matrix_manager, matrix_assignment)
    assert_equal [0, 1, 2, 0],
      assignment_route(callback_routing, callback_manager, callback_assignment)
  end

  def test_read_assignment_from_routes_converts_routes_before_native_work
    routing = ORTools::RoutingModel.new(
      ORTools::RoutingIndexManager.new(2, 1, 0)
    )

    error = assert_raises(TypeError) do
      routing.read_assignment_from_routes([[Object.new]], true)
    end

    assert_equal "no implicit conversion of Object into Integer", error.message
  end

  def test_concurrent_reads_keep_separate_converted_routes
    skip if valgrind?

    first_routing, first_manager = build_setup_model
    second_routing, second_manager = build_setup_model
    first_routing.close_model
    second_routing.close_model
    first_nodes = (1...NODE_COUNT).to_a
    second_nodes = first_nodes.reverse
    ready = Queue.new
    start = Queue.new
    readers = [
      Thread.new do
        ready << true
        start.pop
        first_routing.read_assignment_from_routes(
          [first_nodes, [], [], []],
          true
        )
      end,
      Thread.new do
        ready << true
        start.pop
        second_routing.read_assignment_from_routes(
          [second_nodes, [], [], []],
          true
        )
      end
    ]
    2.times { ready.pop }
    2.times { start << true }

    observed_overlap = false
    while readers.any?(&:alive?)
      observed_overlap ||= readers.all? do |reader|
        reader.backtrace_locations&.any? do |location|
          location.base_label == "_read_assignment_from_routes"
        end
      end
      Thread.pass
    end
    first_assignment, second_assignment = readers.map(&:value)

    assert observed_overlap,
      "expected both native reads to overlap on separate models"
    assert_equal [0, *first_nodes, 0],
      assignment_route(first_routing, first_manager, first_assignment)
    assert_equal [0, *second_nodes, 0],
      assignment_route(second_routing, second_manager, second_assignment)
  ensure
    readers&.each(&:join)
  end

  def test_read_assignment_is_non_owning
    routing, = build_result_model
    assignment = routing.read_assignment_from_routes([[1, 2]], true)
    assert_equal 16, assignment.objective_value

    assignment = nil
    GC.start

    replacement = routing.read_assignment_from_routes([[2, 1]], true)
    assert_equal 16, replacement.objective_value
  end

  private

  def build_setup_model
    manager = ORTools::RoutingIndexManager.new(NODE_COUNT, VEHICLE_COUNT, 0)
    routing = ORTools::RoutingModel.new(manager)
    transit = routing.register_unary_transit_vector(
      Array.new(NODE_COUNT + VEHICLE_COUNT, 1)
    )
    routing.set_arc_cost_evaluator_of_all_vehicles(transit)
    3.times do |index|
      routing.add_dimension(
        transit,
        10,
        NODE_COUNT * 2,
        true,
        "Dimension#{index}"
      )
    end
    (1...NODE_COUNT).each do |node|
      routing.add_disjunction([manager.node_to_index(node)], 100)
    end

    [routing, manager]
  end

  def build_callback_model(&callback)
    manager = ORTools::RoutingIndexManager.new(3, 1, 0)
    routing = ORTools::RoutingModel.new(manager)
    transit = routing.register_transit_callback(callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit)
    routing.add_dimension(transit, 0, 100, true, "Time")
    [routing, manager]
  end

  def build_result_model(callback: false)
    distances = [
      [0, 4, 9],
      [4, 0, 3],
      [9, 3, 0]
    ]
    manager = ORTools::RoutingIndexManager.new(3, 1, 0)
    routing = ORTools::RoutingModel.new(manager)
    transit = if callback
      routing.register_transit_callback(
        lambda do |from_index, to_index|
          distances[manager.index_to_node(from_index)][manager.index_to_node(to_index)]
        end
      )
    else
      routing.register_transit_matrix(distances)
    end
    routing.set_arc_cost_evaluator_of_all_vehicles(transit)
    [routing, manager]
  end

  def assignment_route(routing, manager, assignment)
    index = routing.start(0)
    route = []
    loop do
      route << manager.index_to_node(index)
      break if routing.end?(index)
      index = assignment.value(routing.next_var(index))
    end
    route
  end

  def assert_peer_runs_during(native_frame)
    started = Queue.new
    caller = Thread.new do
      started << true
      yield
    end
    started.pop

    observed_native_frame = false
    while caller.alive?
      observed_native_frame ||= caller
        .backtrace_locations
        &.any? { |location| location.base_label == native_frame }
      Thread.pass
    end
    result = caller.value

    assert observed_native_frame,
      "expected the peer Ruby thread to observe #{native_frame} while it was running"
    result
  ensure
    caller&.join
  end
end
