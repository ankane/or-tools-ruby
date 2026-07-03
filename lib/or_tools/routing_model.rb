module ORTools
  class RoutingModel
    def solve(
      solution_limit: nil,
      time_limit: nil,
      lns_time_limit: nil,
      first_solution_strategy: nil,
      local_search_metaheuristic: nil,
      log_search: nil
    )
      search_parameters = ORTools.default_routing_search_parameters
      search_parameters.solution_limit = solution_limit if solution_limit
      search_parameters.time_limit = time_limit if time_limit
      search_parameters.lns_time_limit = lns_time_limit if lns_time_limit
      search_parameters.first_solution_strategy = first_solution_strategy if first_solution_strategy
      search_parameters.local_search_metaheuristic = local_search_metaheuristic if local_search_metaheuristic
      search_parameters.log_search = log_search unless log_search.nil?
      solve_with_parameters(search_parameters)
    end

    def add_disjunction(indices, penalty, max_cardinality = 1, penalty_cost_behavior = :penalize_once)
      _add_disjunction(indices, penalty, max_cardinality, penalty_cost_behavior)
    end

    # Ruby-proc transit callbacks re-enter Ruby during the solve, so the GVL
    # can only be released when a model registers none of them.
    def register_transit_callback(callback)
      @ruby_transit_callbacks = true
      _register_transit_callback(callback)
    end

    def register_unary_transit_callback(callback)
      @ruby_transit_callbacks = true
      _register_unary_transit_callback(callback)
    end

    def solve_with_parameters(search_parameters)
      _solve_with_parameters(search_parameters, !ruby_transit_callbacks?)
    end

    def solve_from_assignment_with_parameters(assignment, search_parameters)
      _solve_from_assignment_with_parameters(assignment, search_parameters, !ruby_transit_callbacks?)
    end

    private

    def ruby_transit_callbacks?
      defined?(@ruby_transit_callbacks) && @ruby_transit_callbacks
    end
  end
end
