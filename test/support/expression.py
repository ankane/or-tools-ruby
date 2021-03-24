from ortools.sat.python import cp_model

model = cp_model.CpModel()

x = model.NewIntVar(0, 1, 'x')
model.Add(x == x + 1).OnlyEnforceIf(x)

solver = cp_model.CpSolver()
status = solver.Solve(model)
print(status == cp_model.OPTIMAL)
print(solver.Value(x))
