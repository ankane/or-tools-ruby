from ortools.sat.python import cp_model

model = cp_model.CpModel()

x = model.NewIntVar(0, 1, 'x')
y = model.NewIntVar(0, 1, 'y')
z = model.NewIntVar(0, 1, 'z')

# model.Add(sum([x, y]) == z)
model.Add(x + y == z)

with open('test/support/proto.txt', 'w') as file:
    file.write(str(model))
