from ortools.sat.python import cp_model

print('add_max_equality')

model = cp_model.CpModel()
x = model.NewIntVar(-7, 7, 'x')
y = model.NewIntVar(0, 7, 'y')
model.AddMaxEquality(y, [x, model.NewConstant(0)])

solver = cp_model.CpSolver()
status = solver.Solve(model)
print(status == cp_model.OPTIMAL)
print(solver.Value(x))
print(solver.Value(y))

print('only_enforce_if')

model = cp_model.CpModel()
x = model.NewIntVar(0, 1, 'x')
model.Add(x == x + 1).OnlyEnforceIf(x)

solver = cp_model.CpSolver()
status = solver.Solve(model)
print(status == cp_model.OPTIMAL)
print(solver.Value(x))
