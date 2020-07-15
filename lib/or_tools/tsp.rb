module ORTools
  class TSP
    attr_reader :route, :route_indexes, :distances, :total_distance

    DISTANCE_SCALE = 1000
    DEGREES_TO_RADIANS = Math::PI / 180

    def initialize(locations)
      raise ArgumentError, "Locations must have latitude and longitude" unless locations.all? { |l| l[:latitude] && l[:longitude] }
      raise ArgumentError, "Latitude must be between -90 and 90" unless locations.all? { |l| l[:latitude] >= -90 && l[:latitude] <= 90 }
      raise ArgumentError, "Longitude must be between -180 and 180" unless locations.all? { |l| l[:longitude] >= -180 && l[:longitude] <= 180 }
      raise ArgumentError, "Must be at least two locations" unless locations.size >= 2

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

      @route_indexes = []
      @distances = []

      index = routing.start(0)
      while !routing.end?(index)
        @route_indexes << manager.index_to_node(index)
        previous_index = index
        index = assignment.value(routing.next_var(index))
        @distances << routing.arc_cost_for_vehicle(previous_index, index, 0) / DISTANCE_SCALE.to_f
      end
      @route_indexes << manager.index_to_node(index)
      @route = locations.values_at(*@route_indexes)
      @total_distance = @distances.sum
    end

    private

    def distance(from, to)
      from_lat = from[:latitude] * DEGREES_TO_RADIANS
      from_lng = from[:longitude] * DEGREES_TO_RADIANS
      to_lat = to[:latitude] * DEGREES_TO_RADIANS
      to_lng = to[:longitude] * DEGREES_TO_RADIANS
      2 * 6371 * Math.asin(Math.sqrt(Math.sin((to_lat - from_lat) / 2.0)**2 + Math.cos(from_lat) * Math.cos(to_lat) * Math.sin((from_lng - to_lng) / 2.0)**2))
    end
  end
end
