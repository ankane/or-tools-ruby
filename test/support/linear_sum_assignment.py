"""Solve assignment problem using linear assignment solver."""
from ortools.graph import pywrapgraph


def main():
    """Linear Sum Assignment example."""
    assignment = pywrapgraph.LinearSumAssignment()

    costs = [
        [90, 76, 75, 70],
        [35, 85, 55, 65],
        [125, 95, 90, 105],
        [45, 110, 95, 115],
    ]
    num_workers = len(costs)
    num_tasks = len(costs[0])

    for worker in range(num_workers):
        for task in range(num_tasks):
            if costs[worker][task]:
                assignment.AddArcWithCost(worker, task, costs[worker][task])

    status = assignment.Solve()

    if status == assignment.OPTIMAL:
        print(f'Total cost = {assignment.OptimalCost()}\n')
        for i in range(0, assignment.NumNodes()):
            print(f'Worker {i} assigned to task {assignment.RightMate(i)}.' +
                  f'  Cost = {assignment.AssignmentCost(i)}')
    elif status == assignment.INFEASIBLE:
        print('No assignment is possible.')
    elif status == assignment.POSSIBLE_OVERFLOW:
        print(
            'Some input costs are too large and may cause an integer overflow.')


if __name__ == '__main__':
    main()
