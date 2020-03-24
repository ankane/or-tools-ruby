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

    assignment = routing.solve(first_solution_strategy: :path_cheapest_arc)

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

    solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

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

  def test_cvrp
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
    data[:demands] = [0, 1, 1, 2, 4, 2, 4, 8, 8, 1, 2, 1, 2, 4, 4, 8, 8]
    data[:vehicle_capacities] = [15, 15, 15, 15]
    data[:num_vehicles] = 4
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])
    routing = ORTools::RoutingModel.new(manager)

    distance_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:distance_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(distance_callback)

    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    demand_callback = lambda do |from_index|
      from_node = manager.index_to_node(from_index)
      data[:demands][from_node]
    end

    demand_callback_index = routing.register_unary_transit_callback(demand_callback)
    routing.add_dimension_with_vehicle_capacity(
      demand_callback_index,
      0,  # null capacity slack
      data[:vehicle_capacities],  # vehicle maximum capacities
      true,  # start cumul to zero
      "Capacity"
    )

    solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

    total_distance = 0
    total_load = 0
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
      route_distance = 0
      route_load = 0
      while !routing.end?(index)
        node_index = manager.index_to_node(index)
        route_load += data[:demands][node_index]
        plan_output += " #{node_index} Load(#{route_load}) -> "
        previous_index = index
        index = solution.value(routing.next_var(index))
        route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
      end
      plan_output += " #{manager.index_to_node(index)} Load(#{route_load})\n"
      plan_output += "Distance of the route: #{route_distance}m\n"
      plan_output += "Load of the route: #{route_load}\n\n"
      puts plan_output
      total_distance += route_distance
      total_load += route_load
    end
    puts "Total distance of all routes: #{total_distance}m"
    puts "Total load of all routes: #{total_load}"
  end

  def test_pickup_delivery
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
    data[:pickups_deliveries] = [
      [1, 6],
      [2, 10],
      [4, 3],
      [5, 9],
      [7, 8],
      [15, 11],
      [13, 12],
      [16, 14],
    ]
    data[:num_vehicles] = 4
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])

    routing = ORTools::RoutingModel.new(manager)

    distance_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:distance_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(distance_callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    dimension_name = "Distance"
    routing.add_dimension(
      transit_callback_index,
      0,  # no slack
      3000,  # vehicle maximum travel distance
      true,  # start cumul to zero
      dimension_name
    )
    distance_dimension = routing.mutable_dimension(dimension_name)
    distance_dimension.global_span_cost_coefficient = 100

    data[:pickups_deliveries].each do |request|
      pickup_index = manager.node_to_index(request[0])
      delivery_index = manager.node_to_index(request[1])
      routing.add_pickup_and_delivery(pickup_index, delivery_index)
      routing.solver.add(routing.vehicle_var(pickup_index) == routing.vehicle_var(delivery_index))
      routing.solver.add(distance_dimension.cumul_var(pickup_index) <= distance_dimension.cumul_var(delivery_index))
    end

    solution = routing.solve(first_solution_strategy: :parallel_cheapest_insertion)

    total_distance = 0
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
      route_distance = 0
      while !routing.end?(index)
        plan_output += " #{manager.index_to_node(index)} -> "
        previous_index = index
        index = solution.value(routing.next_var(index))
        route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
      end
      plan_output += "#{manager.index_to_node(index)}\n"
      plan_output += "Distance of the route: #{route_distance}m\n\n"
      puts plan_output
      total_distance += route_distance
    end
    puts "Total Distance of all routes: #{total_distance}m"
  end

  def test_vrptw
    data = {}
    data[:time_matrix] = [
      [0, 6, 9, 8, 7, 3, 6, 2, 3, 2, 6, 6, 4, 4, 5, 9, 7],
      [6, 0, 8, 3, 2, 6, 8, 4, 8, 8, 13, 7, 5, 8, 12, 10, 14],
      [9, 8, 0, 11, 10, 6, 3, 9, 5, 8, 4, 15, 14, 13, 9, 18, 9],
      [8, 3, 11, 0, 1, 7, 10, 6, 10, 10, 14, 6, 7, 9, 14, 6, 16],
      [7, 2, 10, 1, 0, 6, 9, 4, 8, 9, 13, 4, 6, 8, 12, 8, 14],
      [3, 6, 6, 7, 6, 0, 2, 3, 2, 2, 7, 9, 7, 7, 6, 12, 8],
      [6, 8, 3, 10, 9, 2, 0, 6, 2, 5, 4, 12, 10, 10, 6, 15, 5],
      [2, 4, 9, 6, 4, 3, 6, 0, 4, 4, 8, 5, 4, 3, 7, 8, 10],
      [3, 8, 5, 10, 8, 2, 2, 4, 0, 3, 4, 9, 8, 7, 3, 13, 6],
      [2, 8, 8, 10, 9, 2, 5, 4, 3, 0, 4, 6, 5, 4, 3, 9, 5],
      [6, 13, 4, 14, 13, 7, 4, 8, 4, 4, 0, 10, 9, 8, 4, 13, 4],
      [6, 7, 15, 6, 4, 9, 12, 5, 9, 6, 10, 0, 1, 3, 7, 3, 10],
      [4, 5, 14, 7, 6, 7, 10, 4, 8, 5, 9, 1, 0, 2, 6, 4, 8],
      [4, 8, 13, 9, 8, 7, 10, 3, 7, 4, 8, 3, 2, 0, 4, 5, 6],
      [5, 12, 9, 14, 12, 6, 6, 7, 3, 3, 4, 7, 6, 4, 0, 9, 2],
      [9, 10, 18, 6, 8, 12, 15, 8, 13, 9, 13, 3, 4, 5, 9, 0, 9],
      [7, 14, 9, 16, 14, 8, 5, 10, 6, 5, 4, 10, 8, 6, 2, 9, 0],
    ]
    data[:time_windows] = [
      [0, 5],  # depot
      [7, 12],  # 1
      [10, 15],  # 2
      [16, 18],  # 3
      [10, 13],  # 4
      [0, 5],  # 5
      [5, 10],  # 6
      [0, 4],  # 7
      [5, 10],  # 8
      [0, 3],  # 9
      [10, 16],  # 10
      [10, 15],  # 11
      [0, 5],  # 12
      [5, 10],  # 13
      [7, 8],  # 14
      [10, 15],  # 15
      [11, 15],  # 16
    ]
    data[:num_vehicles] = 4
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:time_matrix].size, data[:num_vehicles], data[:depot])
    routing = ORTools::RoutingModel.new(manager)

    time_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:time_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(time_callback)
    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
    time = "Time"
    routing.add_dimension(
      transit_callback_index,
      30,  # allow waiting time
      30,  # maximum time per vehicle
      false,  # don't force start cumul to zero
      time
    )
    time_dimension = routing.mutable_dimension(time)

    data[:time_windows].each_with_index do |time_window, location_idx|
      next if location_idx == 0
      index = manager.node_to_index(location_idx)
      time_dimension.cumul_var(index).set_range(time_window[0], time_window[1])
    end

    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      time_dimension.cumul_var(index).set_range(data[:time_windows][0][0], data[:time_windows][0][1])
    end

    data[:num_vehicles].times do |i|
      routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.start(i)))
      routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.end(i)))
    end

    solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

    time_dimension = routing.mutable_dimension("Time")
    total_time = 0
    routes = []
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
      route = []
      while !routing.end?(index)
        time_var = time_dimension.cumul_var(index)
        plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)}) -> "
        route << manager.index_to_node(index)
        index = solution.value(routing.next_var(index))
      end
      route << manager.index_to_node(index)
      routes << route
      time_var = time_dimension.cumul_var(index)
      plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)})\n"
      plan_output += "Time of the route: #{solution.min(time_var)}min\n\n"
      # puts plan_output
      total_time += solution.min(time_var)
    end

    assert_equal [[0, 9, 14, 16, 0], [0, 7, 1, 4, 3, 0], [0, 12, 13, 15, 11, 0], [0, 5, 8, 6, 2, 10, 0]], routes
    assert_equal 82, total_time
  end

  def test_cvrptw_resources
    data = {}
    data[:time_matrix] = [
      [0, 6, 9, 8, 7, 3, 6, 2, 3, 2, 6, 6, 4, 4, 5, 9, 7],
      [6, 0, 8, 3, 2, 6, 8, 4, 8, 8, 13, 7, 5, 8, 12, 10, 14],
      [9, 8, 0, 11, 10, 6, 3, 9, 5, 8, 4, 15, 14, 13, 9, 18, 9],
      [8, 3, 11, 0, 1, 7, 10, 6, 10, 10, 14, 6, 7, 9, 14, 6, 16],
      [7, 2, 10, 1, 0, 6, 9, 4, 8, 9, 13, 4, 6, 8, 12, 8, 14],
      [3, 6, 6, 7, 6, 0, 2, 3, 2, 2, 7, 9, 7, 7, 6, 12, 8],
      [6, 8, 3, 10, 9, 2, 0, 6, 2, 5, 4, 12, 10, 10, 6, 15, 5],
      [2, 4, 9, 6, 4, 3, 6, 0, 4, 4, 8, 5, 4, 3, 7, 8, 10],
      [3, 8, 5, 10, 8, 2, 2, 4, 0, 3, 4, 9, 8, 7, 3, 13, 6],
      [2, 8, 8, 10, 9, 2, 5, 4, 3, 0, 4, 6, 5, 4, 3, 9, 5],
      [6, 13, 4, 14, 13, 7, 4, 8, 4, 4, 0, 10, 9, 8, 4, 13, 4],
      [6, 7, 15, 6, 4, 9, 12, 5, 9, 6, 10, 0, 1, 3, 7, 3, 10],
      [4, 5, 14, 7, 6, 7, 10, 4, 8, 5, 9, 1, 0, 2, 6, 4, 8],
      [4, 8, 13, 9, 8, 7, 10, 3, 7, 4, 8, 3, 2, 0, 4, 5, 6],
      [5, 12, 9, 14, 12, 6, 6, 7, 3, 3, 4, 7, 6, 4, 0, 9, 2],
      [9, 10, 18, 6, 8, 12, 15, 8, 13, 9, 13, 3, 4, 5, 9, 0, 9],
      [7, 14, 9, 16, 14, 8, 5, 10, 6, 5, 4, 10, 8, 6, 2, 9, 0]
    ]
    data[:time_windows] = [
      [0, 5],  # depot
      [7, 12],  # 1
      [10, 15],  # 2
      [5, 14],  # 3
      [5, 13],  # 4
      [0, 5],  # 5
      [5, 10],  # 6
      [0, 10],  # 7
      [5, 10],  # 8
      [0, 5],  # 9
      [10, 16],  # 10
      [10, 15],  # 11
      [0, 5],  # 12
      [5, 10],  # 13
      [7, 12],  # 14
      [10, 15],  # 15
      [5, 15],  # 16
    ]
    data[:num_vehicles] = 4
    data[:vehicle_load_time] = 5
    data[:vehicle_unload_time] = 5
    data[:depot_capacity] = 2
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:time_matrix].size, data[:num_vehicles], data[:depot])

    routing = ORTools::RoutingModel.new(manager)

    time_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:time_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(time_callback)

    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    time = "Time"
    routing.add_dimension(
      transit_callback_index,
      60,  # allow waiting time
      60,  # maximum time per vehicle
      false,  # don't force start cumul to zero
      time
    )
    time_dimension = routing.mutable_dimension(time)
    data[:time_windows].each_with_index do |time_window, location_idx|
      next if location_idx == 0
      index = manager.node_to_index(location_idx)
      time_dimension.cumul_var(index).set_range(time_window[0], time_window[1])
    end

    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      time_dimension.cumul_var(index).set_range(data[:time_windows][0][0], data[:time_windows][0][1])
    end

    solver = routing.solver
    intervals = []
    data[:num_vehicles].times do |i|
      intervals << solver.fixed_duration_interval_var(
        time_dimension.cumul_var(routing.start(i)),
        data[:vehicle_load_time],
        "depot_interval"
      )
      intervals << solver.fixed_duration_interval_var(
        time_dimension.cumul_var(routing.end(i)),
        data[:vehicle_unload_time],
        "depot_interval"
      )
    end

    depot_usage = [1] * intervals.size
    solver.add(solver.cumulative(intervals, depot_usage, data[:depot_capacity], "depot"))

    data[:num_vehicles].times do |i|
      routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.start(i)))
      routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.end(i)))
    end

    solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

    routes = []
    time_dimension = routing.mutable_dimension("Time")
    total_time = 0
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
      route = []
      while !routing.end?(index)
        time_var = time_dimension.cumul_var(index)
        plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)}) -> "
        route << manager.index_to_node(index)
        index = solution.value(routing.next_var(index))
      end
      route << manager.index_to_node(index)
      routes << route
      time_var = time_dimension.cumul_var(index)
      plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)})\n"
      plan_output += "Time of the route: #{solution.min(time_var)}min\n\n"
      total_time += solution.min(time_var)
    end

    assert_equal [[0, 8, 14, 16, 0], [0, 12, 13, 15, 11, 0], [0, 7, 1, 4, 3, 0], [0, 9, 5, 6, 2, 10, 0]], routes
    assert_equal 90, total_time
  end

  def test_penalties
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
    data[:demands] = [0, 1, 1, 3, 6, 3, 6, 8, 8, 1, 2, 1, 2, 6, 6, 8, 8]
    data[:vehicle_capacities] = [15, 15, 15, 15]
    data[:num_vehicles] = 4
    data[:depot] = 0

    manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])

    routing = ORTools::RoutingModel.new(manager)

    distance_callback = lambda do |from_index, to_index|
      from_node = manager.index_to_node(from_index)
      to_node = manager.index_to_node(to_index)
      data[:distance_matrix][from_node][to_node]
    end

    transit_callback_index = routing.register_transit_callback(distance_callback)

    routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

    demand_callback = lambda do |from_index|
      from_node = manager.index_to_node(from_index)
      data[:demands][from_node]
    end

    demand_callback_index = routing.register_unary_transit_callback(demand_callback)
    routing.add_dimension_with_vehicle_capacity(
      demand_callback_index,
      0,  # null capacity slack
      data[:vehicle_capacities],  # vehicle maximum capacities
      true,  # start cumul to zero
      "Capacity"
    )

    penalty = 1000
    1.upto(data[:distance_matrix].size - 1) do |node|
      routing.add_disjunction([manager.node_to_index(node)], penalty)
    end

    assignment = routing.solve(first_solution_strategy: :path_cheapest_arc)

    dropped_nodes = []
    routing.size.times do |node|
      next if routing.start?(node) || routing.end?(node)

      if assignment.value(routing.next_var(node)) == node
        dropped_nodes << manager.index_to_node(node)
      end
    end
    assert_equal [6, 15], dropped_nodes

    total_distance = 0
    total_load = 0
    routes = []
    data[:num_vehicles].times do |vehicle_id|
      index = routing.start(vehicle_id)
      plan_output = "Route for vehicle #{vehicle_id}:\n"
      route_distance = 0
      route_load = 0
      route = []
      while !routing.end?(index)
        node_index = manager.index_to_node(index)
        route_load += data[:demands][node_index]
        previous_index = index
        index = assignment.value(routing.next_var(index))
        route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
        route << node_index
      end
      route << manager.index_to_node(index)
      routes << route
      total_distance += route_distance
      total_load += route_load
    end

    assert_equal [[0, 9, 14, 16, 0], [0, 12, 11, 4, 3, 1, 0], [0, 7, 13, 0], [0, 8, 10, 2, 5, 0]], routes
    assert_equal 5936, total_distance
    assert_equal 56, total_load
  end

  # https://developers.google.com/optimization/routing/routing_options
  def test_search_parameters
    search_parameters = ORTools.default_routing_search_parameters
    search_parameters.solution_limit = 10
    search_parameters.time_limit = 10 # seconds
    search_parameters.lns_time_limit = 10 # seconds
    search_parameters.first_solution_strategy = :path_cheapest_arc
    search_parameters.local_search_metaheuristic = :guided_local_search
    search_parameters.log_search = true
  end
end
