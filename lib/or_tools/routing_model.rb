module ORTools
  class RoutingModel
    def solve(solution_limit: nil, time_limit: nil, lns_time_limit: nil,
      first_solution_strategy: nil, local_search_metaheuristic: nil,
      log_search: nil)

      search_parameters = ORTools.default_routing_search_parameters
      search_parameters.solution_limit = solution_limit if solution_limit
      search_parameters.time_limit = time_limit if time_limit
      search_parameters.lns_time_limit = lns_time_limit if lns_time_limit
      search_parameters.first_solution_strategy = first_solution_strategy if first_solution_strategy
      search_parameters.local_search_metaheuristic = local_search_metaheuristic if local_search_metaheuristic
      search_parameters.log_search = log_search unless log_search.nil?
      solve_with_parameters(search_parameters)
    end

    # previous names
    alias_method :pickup_index_pairs, :pickup_positions
    alias_method :delivery_index_pairs, :delivery_positions
  end
end
