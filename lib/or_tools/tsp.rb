module ORTools
  class TSP
    attr_reader :route, :distances

    DISTANCE_SCALE = 1000
    DEGREE_TO_RADIANS = Math::PI / 180

    def initialize(locations)
      distance_matrix =
        locations.map do |from|
          locations.map do |to|
            # must be integers
            (distance(from, to) * DISTANCE_SCALE).to_i
          end
        end

      manager = ORTools::RoutingIndexManager.new(locations.size, 1, 0)
      routing = ORTools::RoutingModel.new(manager)

      distance_callback = lambda do |from_index, to_index|
        from_node = manager.index_to_node(from_index)
        to_node = manager.index_to_node(to_index)
        distance_matrix[from_node][to_node]
      end

      transit_callback_index = routing.register_transit_callback(distance_callback)
      routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
      assignment = routing.solve(first_solution_strategy: :path_cheapest_arc)

      @route = []
      @distances = []

      index = routing.start(0)
      while !routing.end?(index)
        @route << locations[manager.index_to_node(index)]
        previous_index = index
        index = assignment.value(routing.next_var(index))
        @distances << routing.arc_cost_for_vehicle(previous_index, index, 0) / DISTANCE_SCALE.to_f
      end
      @route << locations[manager.index_to_node(index)]
    end

    private

    def distance(from, to)
      from_lat = from[:latitude] * DEGREE_TO_RADIANS
      from_lng = from[:longitude] * DEGREE_TO_RADIANS
      to_lat = to[:latitude] * DEGREE_TO_RADIANS
      to_lng = to[:longitude] * DEGREE_TO_RADIANS
      2 * 6371 * Math.asin(Math.sqrt(Math.sin((to_lat - from_lat) / 2.0)**2 + Math.cos(from_lat) * Math.cos(to_lat) * Math.sin((from_lng - to_lng) / 2.0)**2))
    end
  end
end
