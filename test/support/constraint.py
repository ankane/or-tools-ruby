from __future__ import print_function
from ortools.sat.python import cp_model


def main():
  model = cp_model.CpModel()
  var_upper_bound = max(50, 45, 37)
  x = model.NewIntVar(0, var_upper_bound, 'x')
  y = model.NewIntVar(0, var_upper_bound, 'y')
  z = model.NewIntVar(0, var_upper_bound, 'z')

  print((2*x + 7*y + 3*z).__class__)
  print((2*x + 7*y + 3*z <= 50).__class__)
  model.Add(2*x + 7*y + 3*z <= 50)
  model.Add(3*x - 5*y + 7*z <= 45)
  model.Add(5*x + 2*y - 6*z <= 37)

  model.Maximize(2*x + 2*y + 3*z)

  solver = cp_model.CpSolver()
  status = solver.Solve(model)

  if status == cp_model.OPTIMAL:
    print('Maximum of objective function: %i' % solver.ObjectiveValue())
    print()
    print('x value: ', solver.Value(x))
    print('y value: ', solver.Value(y))
    print('z value: ', solver.Value(z))


if __name__ == '__main__':
  main()
