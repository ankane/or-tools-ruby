module ORTools
  class RoutingIndexManager
    def self.new(num_nodes, num_vehicles, starts, ends = nil)
      if ends
        _new_starts_ends(num_nodes, num_vehicles, starts, ends)
      else
        _new_depot(num_nodes, num_vehicles, starts)
      end
    end
  end
end
