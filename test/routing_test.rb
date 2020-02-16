require_relative "test_helper"

class RoutingTest < Minitest::Test
  # https://developers.google.com/optimization/routing/tsp
  def test_tsp
    data = {}
    data[:distance_matrix] = [
      [0, 2451, 713, 1018, 1631, 1374, 2408, 213, 2571, 875, 1420, 2145, 1972],
      [2451, 0, 1745, 1524, 831, 1240, 959, 2596, 403, 1589, 1374, 357, 579],
      [713, 1745, 0, 355, 920, 803, 1737, 851, 1858, 262, 940, 1453, 1260],
      [1018, 1524, 355, 0, 700, 862, 1395, 1123, 1584, 466, 1056, 1280, 987],
      [1631, 831, 920, 700, 0, 663, 1021, 1769, 949, 796, 879, 586, 371],
      [1374, 1240, 803, 862, 663, 0, 1681, 1551, 1765, 547, 225, 887, 999],
      [2408, 959, 1737, 1395, 1021, 1681, 0, 2493, 678, 1724, 1891, 1114, 701],
      [213, 2596, 851, 1123, 1769, 1551, 2493, 0, 2699, 1038, 1605, 2300, 2099],
      [2571, 403, 1858, 1584, 949, 1765, 678, 2699, 0, 1744, 1645, 653, 600],
      [875, 1589, 262, 466, 796, 547, 1724, 1038, 1744, 0, 679, 1272, 1162],
      [1420, 1374, 940, 1056, 879, 225, 1891, 1605, 1645, 679, 0, 1017, 1200],
      [2145, 357, 1453, 1280, 586, 887, 1114, 2300, 653, 1272, 1017, 0, 504],
      [1972, 579, 1260, 987, 371, 999, 701, 2099, 600, 1162, 1200, 504, 0]
    ]
    data[:num_vehicles] = 1
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
    routing = ORTools::RoutingModel.new(manager)

    distance_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:distance_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(distance_callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    search_parameters = ORTools.default_routing_search_parameters
    search_parameters.first_solution_strategy = :path_cheapest_arc
    assignment = routing.solve_with_parameters(search_parameters)

    assert_equal 7293, assignment.objective_value

    route = []
    index = routing.start(0)
    route_distance = 0
    while !routing.end?(index)
      route << manager.index_to_node(index)
      previous_index = index
      index = assignment.value(routing.next_var(index))
      route_distance += routing.arc_cost_for_vehicle(previous_index, index, 0)
    end
    route << manager.index_to_node(index)

    assert_equal [0, 7, 2, 3, 4, 12, 6, 8, 1, 11, 10, 5, 9, 0], route
    assert_equal 7293, route_distance
  end

  # https://developers.google.com/optimization/routing/vrp
  def test_vrp
    data = {}
    data[:distance_matrix] = [
      [0, 548, 776, 696, 582, 274, 502, 194, 308, 194, 536, 502, 388, 354, 468, 776, 662],
      [548, 0, 684, 308, 194, 502, 730, 354, 696, 742, 1084, 594, 480, 674, 1016, 868, 1210],
      [776, 684, 0, 992, 878, 502, 274, 810, 468, 742, 400, 1278, 1164, 1130, 788, 1552, 754],
      [696, 308, 992, 0, 114, 650, 878, 502, 844, 890, 1232, 514, 628, 822, 1164, 560, 1358],
      [582, 194, 878, 114, 0, 536, 764, 388, 730, 776, 1118, 400, 514, 708, 1050, 674, 1244],
      [274, 502, 502, 650, 536, 0, 228, 308, 194, 240, 582, 776, 662, 628, 514, 1050, 708],
      [502, 730, 274, 878, 764, 228, 0, 536, 194, 468, 354, 1004, 890, 856, 514, 1278, 480],
      [194, 354, 810, 502, 388, 308, 536, 0, 342, 388, 730, 468, 354, 320, 662, 742, 856],
      [308, 696, 468, 844, 730, 194, 194, 342, 0, 274, 388, 810, 696, 662, 320, 1084, 514],
      [194, 742, 742, 890, 776, 240, 468, 388, 274, 0, 342, 536, 422, 388, 274, 810, 468],
      [536, 1084, 400, 1232, 1118, 582, 354, 730, 388, 342, 0, 878, 764, 730, 388, 1152, 354],
      [502, 594, 1278, 514, 400, 776, 1004, 468, 810, 536, 878, 0, 114, 308, 650, 274, 844],
      [388, 480, 1164, 628, 514, 662, 890, 354, 696, 422, 764, 114, 0, 194, 536, 388, 730],
      [354, 674, 1130, 822, 708, 628, 856, 320, 662, 388, 730, 308, 194, 0, 342, 422, 536],
      [468, 1016, 788, 1164, 1050, 514, 514, 662, 320, 274, 388, 650, 536, 342, 0, 764, 194],
      [776, 868, 1552, 560, 674, 1050, 1278, 742, 1084, 810, 1152, 274, 388, 422, 764, 0, 798],
      [662, 1210, 754, 1358, 1244, 708, 480, 856, 514, 468, 354, 844, 730, 536, 194, 798, 0]
    ]
    data[:num_vehicles] = 4
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
    routing = ORTools::RoutingModel.new(manager)

    distance_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:distance_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(distance_callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    dimension_name = "Distance"
    routing.add_dimension(transit_callback_index, 0, 3000, true, dimension_name)
    distance_dimension = routing.mutable_dimension(dimension_name)
    distance_dimension.global_span_cost_coefficient = 100

    search_parameters = ORTools.default_routing_search_parameters
    search_parameters.first_solution_strategy = :path_cheapest_arc
    solution = routing.solve_with_parameters(search_parameters)

    routes = []
    distances = []

    max_route_distance = 0
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      route = []
      route_distance = 0
      while !routing.end?(index)
        route << manager.index_to_node(index)
        previous_index = index
        index = solution.value(routing.next_var(index))
        route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
      end
      route << manager.index_to_node(index)
      routes << route
      distances << route_distance
      max_route_distance = [route_distance, max_route_distance].max
    end

    assert_equal [0, 8, 6, 2, 5, 0], routes[0]
    assert_equal 1552, distances[0]

    assert_equal [0, 7, 1, 4, 3, 0], routes[1]
    assert_equal 1552, distances[1]

    assert_equal [0, 9, 10, 16, 14, 0], routes[2]
    assert_equal 1552, distances[2]

    assert_equal [0, 12, 11, 15, 13, 0], routes[3]
    assert_equal 1552, distances[3]

    assert_equal 1552, max_route_distance
  end

  def test_search_parameters
    search_parameters = ORTools.default_routing_search_parameters
    search_parameters.first_solution_strategy = :path_cheapest_arc
    search_parameters.local_search_metaheuristic = :guided_local_search
    search_parameters.log_search = true
    search_parameters.time_limit = 10 # seconds
  end
end
