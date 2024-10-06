from ortools.math_opt.python import mathopt

# Build the model.
model = mathopt.Model(name="getting_started_lp")
x = model.add_variable(lb=-1.0, ub=1.5, name="x")
y = model.add_variable(lb=0.0, ub=1.0, name="y")
model.add_linear_constraint(x + y <= 1.5)
model.maximize(x + 2 * y)

# Set parameters, e.g. turn on logging.
params = mathopt.SolveParameters(enable_output=True)

# Solve and ensure an optimal solution was found with no errors.
# (mathopt.solve may raise a RuntimeError on invalid input or internal solver
# errors.)
result = mathopt.solve(model, mathopt.SolverType.GLOP, params=params)
if result.termination.reason != mathopt.TerminationReason.OPTIMAL:
    raise RuntimeError(f"model failed to solve: {result.termination}")

# Print some information from the result.
print("MathOpt solve succeeded")
print("Objective value:", result.objective_value())
print("x:", result.variable_values()[x])
print("y:", result.variable_values()[y])
