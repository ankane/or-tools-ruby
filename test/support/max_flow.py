"""From Taha 'Introduction to Operations Research', example 6.4-2."""

from __future__ import print_function
from ortools.graph import pywrapgraph

def main():
  """MaxFlow simple interface example."""

  # Define three parallel arrays: start_nodes, end_nodes, and the capacities
  # between each pair. For instance, the arc from node 0 to node 1 has a
  # capacity of 20.

  start_nodes = [0, 0, 0, 1, 1, 2, 2, 3, 3]
  end_nodes = [1, 2, 3, 2, 4, 3, 4, 2, 4]
  capacities = [20, 30, 10, 40, 30, 10, 20, 5, 20]

  # Instantiate a SimpleMaxFlow solver.
  max_flow = pywrapgraph.SimpleMaxFlow()
  # Add each arc.
  for i in range(0, len(start_nodes)):
    max_flow.AddArcWithCapacity(start_nodes[i], end_nodes[i], capacities[i])

  # Find the maximum flow between node 0 and node 4.
  if max_flow.Solve(0, 4) == max_flow.OPTIMAL:
    print('Max flow:', max_flow.OptimalFlow())
    print('')
    print('  Arc    Flow / Capacity')
    for i in range(max_flow.NumArcs()):
      print('%1s -> %1s   %3s  / %3s' % (
          max_flow.Tail(i),
          max_flow.Head(i),
          max_flow.Flow(i),
          max_flow.Capacity(i)))
    print('Source side min-cut:', max_flow.GetSourceSideMinCut())
    print('Sink side min-cut:', max_flow.GetSinkSideMinCut())
  else:
    print('There was an issue with the max flow input.')

if __name__ == '__main__':
  main()
