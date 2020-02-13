from __future__ import print_function
from ortools.graph import pywrapgraph
import time

def main():
  """Solving an Assignment Problem with MinCostFlow"""

  # Instantiate a SimpleMinCostFlow solver.
  min_cost_flow = pywrapgraph.SimpleMinCostFlow()
  # Define the directed graph for the flow.

  start_nodes = [0, 0, 0, 0] + [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4] + [5, 6, 7, 8]
  end_nodes =   [1, 2, 3, 4] + [5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8] + [9, 9, 9, 9]
  capacities =  [1, 1, 1, 1] + [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] + [1, 1, 1, 1 ]
  costs  = ([0, 0, 0, 0] + [90, 76, 75, 70, 35, 85, 55, 65, 125, 95, 90, 105, 45, 110, 95, 115]
                + [0, 0, 0, 0])
  # Define an array of supplies at each node.
  supplies = [4, 0, 0, 0, 0, 0, 0, 0, 0, -4]
  source = 0
  sink = 9
  tasks = 4

  # Add each arc.
  for i in range(len(start_nodes)):
    min_cost_flow.AddArcWithCapacityAndUnitCost(start_nodes[i], end_nodes[i],
                                                capacities[i], costs[i])

  # Add node supplies.

  for i in range(len(supplies)):
    min_cost_flow.SetNodeSupply(i, supplies[i])
  # Find the minimum cost flow between node 0 and node 10.
  if min_cost_flow.Solve() == min_cost_flow.OPTIMAL:
    print('Total cost = ', min_cost_flow.OptimalCost())
    print()
    for arc in range(min_cost_flow.NumArcs()):

      # Can ignore arcs leading out of source or into sink.
      if min_cost_flow.Tail(arc)!=source and min_cost_flow.Head(arc)!=sink:

        # Arcs in the solution have a flow value of 1. Their start and end nodes
        # give an assignment of worker to task.

        if min_cost_flow.Flow(arc) > 0:
          print('Worker %d assigned to task %d.  Cost = %d' % (
                min_cost_flow.Tail(arc),
                min_cost_flow.Head(arc),
                min_cost_flow.UnitCost(arc)))
  else:
    print('There was an issue with the min cost flow input.')
if __name__ == '__main__':
  start_time = time.clock()
  main()
  print()
  print("Time =", time.clock() - start_time, "seconds")
