# OR-Tools

[OR-Tools](https://github.com/google/or-tools) - operations research tools - for Ruby

[![Build Status](https://github.com/ankane/or-tools/workflows/build/badge.svg?branch=master)](https://github.com/ankane/or-tools/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'or-tools'
```

Installation can take a few minutes as OR-Tools downloads and builds.

## Higher Level Interfaces

- [Scheduling](#scheduling)
- [Seating](#seating)
- [Traveling Salesperson Problem (TSP)](#traveling-salesperson-problem-tsp)
- [Sudoku](#sudoku)

### Scheduling

Specify people and their availabililty

```ruby
people = [
  {
    availability: [
      {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")},
      {starts_at: Time.parse("2020-01-02 08:00:00"), ends_at: Time.parse("2020-01-02 16:00:00")}
    ],
    max_hours: 40 # optional, applies to entire scheduling period
  },
  {
    availability: [
      {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")},
      {starts_at: Time.parse("2020-01-03 08:00:00"), ends_at: Time.parse("2020-01-03 16:00:00")}
    ],
    max_hours: 20
  }
]
```

Specify shifts

```ruby
shifts = [
  {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")},
  {starts_at: Time.parse("2020-01-02 08:00:00"), ends_at: Time.parse("2020-01-02 16:00:00")},
  {starts_at: Time.parse("2020-01-03 08:00:00"), ends_at: Time.parse("2020-01-03 16:00:00")}
]
```

Run the scheduler

```ruby
scheduler = ORTools::BasicScheduler.new(people: people, shifts: shifts)
```

The scheduler maximizes the number of assigned hours. A person must be available for the entire shift to be considered for it.

Get assignments (returns indexes of people and shifts)

```ruby
scheduler.assignments
# [
#   {person: 2, shift: 0},
#   {person: 0, shift: 1},
#   {person: 1, shift: 2}
# ]
```

Get assigned hours and total hours

```ruby
scheduler.assigned_hours
scheduler.total_hours
```

Feel free to create an issue if you have a scheduling use case that’s not covered.

### Seating

Create a seating chart based on personal connections. Uses [this approach](https://www.improbable.com/news/2012/Optimal-seating-chart.pdf).

Specify connections

```ruby
connections = [
  {people: ["A", "B", "C"], weight: 2},
  {people: ["C", "D", "E", "F"], weight: 1}
]
```

Use different weights to prioritize seating. For a wedding, it may look like:

```ruby
connections = [
  {people: knows_partner1, weight: 1},
  {people: knows_partner2, weight: 1},
  {people: relationship1, weight: 100},
  {people: relationship2, weight: 100},
  {people: relationship3, weight: 100},
  {people: friend_group1, weight: 10},
  {people: friend_group2, weight: 10},
  # ...
]
```

If two people have multiple connections, weights are added.

Specify tables and their capacity

```ruby
tables = [3, 3]
```

Assign seats

```ruby
seating = ORTools::Seating.new(connections: connections, tables: tables)
```

Each person will have a connection with at least one other person at their table.

Get tables

```ruby
seating.assigned_tables
```

Get assignments by person

```ruby
seating.assignments
```

Get all connections for a person

```ruby
seating.connections_for(person)
```

Get connections for a person at their table

```ruby
seating.connections_for(person, same_table: true)
```

### Traveling Salesperson Problem (TSP)

Create locations - the first location will be the starting and ending point

```ruby
locations = [
  {name: "Tokyo", latitude: 35.6762, longitude: 139.6503},
  {name: "Delhi", latitude: 28.7041, longitude: 77.1025},
  {name: "Shanghai", latitude: 31.2304, longitude: 121.4737},
  {name: "São Paulo", latitude: -23.5505, longitude: -46.6333},
  {name: "Mexico City", latitude: 19.4326, longitude: -99.1332},
  {name: "Cairo", latitude: 30.0444, longitude: 31.2357},
  {name: "Mumbai", latitude: 19.0760, longitude: 72.8777},
  {name: "Beijing", latitude: 39.9042, longitude: 116.4074},
  {name: "Dhaka", latitude: 23.8103, longitude: 90.4125},
  {name: "Osaka", latitude: 34.6937, longitude: 135.5023},
  {name: "New York City", latitude: 40.7128, longitude: -74.0060},
  {name: "Karachi", latitude: 24.8607, longitude: 67.0011},
  {name: "Buenos Aires", latitude: -34.6037, longitude: -58.3816}
]
```

Locations can have any fields - only `latitude` and `longitude` are required

Get route

```ruby
tsp = ORTools::TSP.new(locations)
tsp.route # [{name: "Tokyo", ...}, {name: "Osaka", ...}, ...]
```

Get distances between locations on route

```ruby
tsp.distances # [392.441, 1362.926, 1067.31, ...]
```

Distances are in kilometers - multiply by `0.6214` for miles

Get total distance

```ruby
tsp.total_distance
```

### Sudoku

Create a puzzle with zeros in empty cells

```ruby
grid = [
  [0, 6, 0, 0, 5, 0, 0, 2, 0],
  [0, 0, 0, 3, 0, 0, 0, 9, 0],
  [7, 0, 0, 6, 0, 0, 0, 1, 0],
  [0, 0, 6, 0, 3, 0, 4, 0, 0],
  [0, 0, 4, 0, 7, 0, 1, 0, 0],
  [0, 0, 5, 0, 9, 0, 8, 0, 0],
  [0, 4, 0, 0, 0, 1, 0, 0, 6],
  [0, 3, 0, 0, 0, 8, 0, 0, 0],
  [0, 2, 0, 0, 4, 0, 0, 5, 0]
]
sudoku = ORTools::Sudoku.new(grid)
sudoku.solution
```

It can also solve more advanced puzzles like [The Miracle](https://www.youtube.com/watch?v=yKf9aUIxdb4)

```ruby
grid = [
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 1, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 2, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0]
]
sudoku = ORTools::Sudoku.new(grid, anti_knight: true, anti_king: true, non_consecutive: true)
sudoku.solution
```

And [this 4-digit puzzle](https://www.youtube.com/watch?v=hAyZ9K2EBF0)

```ruby
grid = [
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [3, 8, 4, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 2]
]
sudoku = ORTools::Sudoku.new(grid, x: true, anti_knight: true, magic_square: true)
sudoku.solution
```

## Guides

Linear Optimization

- [The Glop Linear Solver](#the-glop-linear-solver)

Integer Optimization

- [Mixed-Integer Programming](#mixed-integer-programming)

Constraint Optimization

- [CP-SAT Solver](#cp-sat-solver)
- [Solving an Optimization Problem](#solving-an-optimization-problem)
- [Cryptarithmetic](#cryptarithmetic)
- [The N-queens Problem](#the-n-queens-problem)
- [Setting Solver Limits](#setting-solver-limits)

Assignment

- [Assignment](#assignment)
- [Assignment with Teams](#assignment-with-teams)

Routing

- [Traveling Salesperson Problem (TSP)](#traveling-salesperson-problem-tsp-1)
- [Vehicle Routing Problem (VRP)](#vehicle-routing-problem-vrp)
- [Capacity Constraints](#capacity-constraints)
- [Pickups and Deliveries](#pickups-and-deliveries)
- [Time Window Constraints](#time-window-constraints)
- [Resource Constraints](#resource-constraints)
- [Penalties and Dropping Visits](#penalties-and-dropping-visits)
- [Routing Options](#routing-options)

Bin Packing

- [The Knapsack Problem](#the-knapsack-problem)
- [Multiple Knapsacks](#multiple-knapsacks)
- [Bin Packing Problem](#bin-packing-problem)

Network Flows

- [Maximum Flows](#maximum-flows)
- [Minimum Cost Flows](#minimum-cost-flows)
- [Assignment as a Min Cost Flow Problem](#assignment-as-a-min-cost-flow-problem)

Scheduling

- [Employee Scheduling](#employee-scheduling)
- [The Job Shop Problem](#the-job-shop-problem)

Other Examples

- [Sudoku](#sudoku-1)
- [Wedding Seating Chart](#wedding-seating-chart)
- [Set Partitioning](#set-partitioning)

### The Glop Linear Solver

[Guide](https://developers.google.com/optimization/lp/glop)

```ruby
# declare the solver
solver = ORTools::Solver.new("LinearProgrammingExample", :glop)

# create the variables
x = solver.num_var(0, solver.infinity, "x")
y = solver.num_var(0, solver.infinity, "y")

# define the constraints
constraint0 = solver.constraint(-solver.infinity, 14)
constraint0.set_coefficient(x, 1)
constraint0.set_coefficient(y, 2)

constraint1 = solver.constraint(0, solver.infinity)
constraint1.set_coefficient(x, 3)
constraint1.set_coefficient(y, -1)

constraint2 = solver.constraint(-solver.infinity, 2)
constraint2.set_coefficient(x, 1)
constraint2.set_coefficient(y, -1)

# define the objective function
objective = solver.objective
objective.set_coefficient(x, 3)
objective.set_coefficient(y, 4)
objective.set_maximization

# invoke the solver
solver.solve

# display the solution
opt_solution = 3 * x.solution_value + 4 * y.solution_value
puts "Number of variables = #{solver.num_variables}"
puts "Number of constraints = #{solver.num_constraints}"
puts "Solution:"
puts "x = #{x.solution_value}"
puts "y = #{y.solution_value}"
puts "Optimal objective value = #{opt_solution}"
```

### Mixed-Integer Programming

[Guide](https://developers.google.com/optimization/mip/integer_opt)

```ruby
# declare the MIP solver
solver = ORTools::Solver.new("simple_mip_program", :cbc)

# define the variables
infinity = solver.infinity
x = solver.int_var(0.0, infinity, "x")
y = solver.int_var(0.0, infinity, "y")

puts "Number of variables = #{solver.num_variables}"

# define the constraints
c0 = solver.constraint(-infinity, 17.5)
c0.set_coefficient(x, 1)
c0.set_coefficient(y, 7)

c1 = solver.constraint(-infinity, 3.5)
c1.set_coefficient(x, 1);
c1.set_coefficient(y, 0);

puts "Number of constraints = #{solver.num_constraints}"

# define the objective
objective = solver.objective
objective.set_coefficient(x, 1)
objective.set_coefficient(y, 10)
objective.set_maximization

# call the solver
status = solver.solve

# display the solution
if status == :optimal
  puts "Solution:"
  puts "Objective value = #{solver.objective.value}"
  puts "x = #{x.solution_value}"
  puts "y = #{y.solution_value}"
else
  puts "The problem does not have an optimal solution."
end
```

### CP-SAT Solver

[Guide](https://developers.google.com/optimization/cp/cp_solver)

```ruby
# declare the model
model = ORTools::CpModel.new

# create the variables
num_vals = 3
x = model.new_int_var(0, num_vals - 1, "x")
y = model.new_int_var(0, num_vals - 1, "y")
z = model.new_int_var(0, num_vals - 1, "z")

# create the constraint
model.add(x != y)

# call the solver
solver = ORTools::CpSolver.new
status = solver.solve(model)

# display the first solution
if status == :optimal
  puts "x = #{solver.value(x)}"
  puts "y = #{solver.value(y)}"
  puts "z = #{solver.value(z)}"
end
```

### Solving an Optimization Problem

[Guide](https://developers.google.com/optimization/cp/integer_opt_cp)

```ruby
# declare the model
model = ORTools::CpModel.new

# create the variables
var_upper_bound = [50, 45, 37].max
x = model.new_int_var(0, var_upper_bound, "x")
y = model.new_int_var(0, var_upper_bound, "y")
z = model.new_int_var(0, var_upper_bound, "z")

# define the constraints
model.add(x*2 + y*7 + z*3 <= 50)
model.add(x*3 - y*5 + z*7 <= 45)
model.add(x*5 + y*2 - z*6 <= 37)

# define the objective function
model.maximize(x*2 + y*2 + z*3)

# call the solver
solver = ORTools::CpSolver.new
status = solver.solve(model)

if status == :optimal
  puts "Maximum of objective function: #{solver.objective_value}"
  puts
  puts "x value: #{solver.value(x)}"
  puts "y value: #{solver.value(y)}"
  puts "z value: #{solver.value(z)}"
end
```

### Cryptarithmetic

[Guide](https://developers.google.com/optimization/cp/cryptarithmetic)

```ruby
# define the variables
model = ORTools::CpModel.new

base = 10

c = model.new_int_var(1, base - 1, "C")
p = model.new_int_var(0, base - 1, "P")
i = model.new_int_var(1, base - 1, "I")
s = model.new_int_var(0, base - 1, "S")
f = model.new_int_var(1, base - 1, "F")
u = model.new_int_var(0, base - 1, "U")
n = model.new_int_var(0, base - 1, "N")
t = model.new_int_var(1, base - 1, "T")
r = model.new_int_var(0, base - 1, "R")
e = model.new_int_var(0, base - 1, "E")

letters = [c, p, i, s, f, u, n, t, r, e]

# define the constraints
model.add_all_different(letters)

model.add(c * base + p + i * base + s + f * base * base + u * base +
  n == t * base * base * base + r * base * base + u * base + e)

# define the solution printer
class VarArraySolutionPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(variables)
    super()
    @variables = variables
    @solution_count = 0
  end

  def on_solution_callback
    @solution_count += 1
    @variables.each do |v|
      print "%s=%i " % [v.name, value(v)]
    end
    puts
  end
end

# invoke the solver
solver = ORTools::CpSolver.new
solution_printer = VarArraySolutionPrinter.new(letters)
status = solver.search_for_all_solutions(model, solution_printer)

puts
puts "Statistics"
puts "  - status          : %s" % status
puts "  - conflicts       : %i" % solver.num_conflicts
puts "  - branches        : %i" % solver.num_branches
puts "  - wall time       : %f s" % solver.wall_time
puts "  - solutions found : %i" % solution_printer.solution_count
```

### The N-queens Problem

[Guide](https://developers.google.com/optimization/cp/queens)

```ruby
# declare the model
board_size = 8
model = ORTools::CpModel.new

# create the variables
queens = board_size.times.map { |i| model.new_int_var(0, board_size - 1, "x%i" % i) }

# create the constraints
board_size.times do |i|
  diag1 = []
  diag2 = []
  board_size.times do |j|
    q1 = model.new_int_var(0, 2 * board_size, "diag1_%i" % i)
    diag1 << q1
    model.add(q1 == queens[j] + j)
    q2 = model.new_int_var(-board_size, board_size, "diag2_%i" % i)
    diag2 << q2
    model.add(q2 == queens[j] - j)
  end
  model.add_all_different(diag1)
  model.add_all_different(diag2)
end

# create a solution printer
class SolutionPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(variables)
    super()
    @variables = variables
    @solution_count = 0
  end

  def on_solution_callback
    @solution_count += 1
    @variables.each do |v|
      print "%s = %i " % [v.name, value(v)]
    end
    puts
  end
end

# call the solver and display the results
solver = ORTools::CpSolver.new
solution_printer = SolutionPrinter.new(queens)
status = solver.search_for_all_solutions(model, solution_printer)
puts
puts "Solutions found : %i" % solution_printer.solution_count
```

### Setting Solver Limits

[Guide](https://developers.google.com/optimization/cp/cp_tasks)

```ruby
# create the model
model = ORTools::CpModel.new

# create the variables
num_vals = 3
x = model.new_int_var(0, num_vals - 1, "x")
y = model.new_int_var(0, num_vals - 1, "y")
z = model.new_int_var(0, num_vals - 1, "z")

# add an all-different constraint
model.add(x != y)

# create the solver
solver = ORTools::CpSolver.new

# set a time limit of 10 seconds.
solver.parameters.max_time_in_seconds = 10

# solve the model
status = solver.solve(model)

# display the first solution
if status == :optimal
  puts "x = #{solver.value(x)}"
  puts "y = #{solver.value(y)}"
  puts "z = #{solver.value(z)}"
end
```

### Assignment

[Guide](https://developers.google.com/optimization/assignment/assignment_example)

```ruby
# create the data
cost = [[ 90,  76, 75,  70],
        [ 35,  85, 55,  65],
        [125,  95, 90, 105],
        [ 45, 110, 95, 115]]

rows = cost.length
cols = cost[0].length

# create the solver
assignment = ORTools::LinearSumAssignment.new

# add the costs to the solver
rows.times do |worker|
  cols.times do |task|
    if cost[worker][task]
      assignment.add_arc_with_cost(worker, task, cost[worker][task])
    end
  end
end

# invoke the solver
solve_status = assignment.solve
if solve_status == :optimal
  puts "Total cost = #{assignment.optimal_cost}"
  puts
  assignment.num_nodes.times do |i|
    puts "Worker %d assigned to task %d.  Cost = %d" % [
      i,
      assignment.right_mate(i),
      assignment.assignment_cost(i)
    ]
  end
elsif solve_status == :infeasible
  puts "No assignment is possible."
elsif solve_status == :possible_overflow
  puts "Some input costs are too large and may cause an integer overflow."
end
```

### Assignment with Teams

[Guide](https://developers.google.com/optimization/assignment/assignment_teams)

```ruby
# create the solver
solver = ORTools::Solver.new("SolveAssignmentProblemMIP", :cbc)

# create the data
cost = [[90, 76, 75, 70],
        [35, 85, 55, 65],
        [125, 95, 90, 105],
        [45, 110, 95, 115],
        [60, 105, 80, 75],
        [45, 65, 110, 95]]

team1 = [0, 2, 4]
team2 = [1, 3, 5]
team_max = 2

# create the variables
num_workers = cost.length
num_tasks = cost[1].length
x = {}

num_workers.times do |i|
  num_tasks.times do |j|
    x[[i, j]] = solver.bool_var("x[#{i},#{j}]")
  end
end

# create the objective function
solver.minimize(solver.sum(
  num_workers.times.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] * cost[i][j] } }
))

# create the constraints
num_workers.times do |i|
  solver.add(solver.sum(num_tasks.times.map { |j| x[[i, j]] }) <= 1)
end

num_tasks.times do |j|
  solver.add(solver.sum(num_workers.times.map { |i| x[[i, j]] }) == 1)
end

solver.add(solver.sum(team1.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)
solver.add(solver.sum(team2.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)

# invoke the solver
sol = solver.solve

puts "Total cost = #{solver.objective.value}"
puts
num_workers.times do |i|
  num_tasks.times do |j|
    if x[[i, j]].solution_value > 0
      puts "Worker %d assigned to task %d.  Cost = %d" % [
        i,
        j,
        cost[i][j]
      ]
    end
  end
end

puts
puts "Time = #{solver.wall_time} milliseconds"
```

### Traveling Salesperson Problem (TSP)

[Guide](https://developers.google.com/optimization/routing/tsp.html)

```ruby
# create the data
data = {}
data[:distance_matrix] = [
  [0, 2451, 713, 1018, 1631, 1374, 2408, 213, 2571, 875, 1420, 2145, 1972],
  [2451, 0, 1745, 1524, 831, 1240, 959, 2596, 403, 1589, 1374, 357, 579],
  [713, 1745, 0, 355, 920, 803, 1737, 851, 1858, 262, 940, 1453, 1260],
  [1018, 1524, 355, 0, 700, 862, 1395, 1123, 1584, 466, 1056, 1280, 987],
  [1631, 831, 920, 700, 0, 663, 1021, 1769, 949, 796, 879, 586, 371],
  [1374, 1240, 803, 862, 663, 0, 1681, 1551, 1765, 547, 225, 887, 999],
  [2408, 959, 1737, 1395, 1021, 1681, 0, 2493, 678, 1724, 1891, 1114, 701],
  [213, 2596, 851, 1123, 1769, 1551, 2493, 0, 2699, 1038, 1605, 2300, 2099],
  [2571, 403, 1858, 1584, 949, 1765, 678, 2699, 0, 1744, 1645, 653, 600],
  [875, 1589, 262, 466, 796, 547, 1724, 1038, 1744, 0, 679, 1272, 1162],
  [1420, 1374, 940, 1056, 879, 225, 1891, 1605, 1645, 679, 0, 1017, 1200],
  [2145, 357, 1453, 1280, 586, 887, 1114, 2300, 653, 1272, 1017, 0, 504],
  [1972, 579, 1260, 987, 371, 999, 701, 2099, 600, 1162, 1200, 504, 0]
]
data[:num_vehicles] = 1
data[:depot] = 0

# create the distance callback
manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

# run the solver
assignment = routing.solve(first_solution_strategy: :path_cheapest_arc)

# print the solution
puts "Objective: #{assignment.objective_value} miles"
index = routing.start(0)
plan_output = String.new("Route for vehicle 0:\n")
route_distance = 0
while !routing.end?(index)
  plan_output += " #{manager.index_to_node(index)} ->"
  previous_index = index
  index = assignment.value(routing.next_var(index))
  route_distance += routing.arc_cost_for_vehicle(previous_index, index, 0)
end
plan_output += " #{manager.index_to_node(index)}\n"
puts plan_output
```

### Vehicle Routing Problem (VRP)

[Guide](https://developers.google.com/optimization/routing/vrp)

```ruby
# create the data
data = {}
data[:distance_matrix] = [
  [0, 548, 776, 696, 582, 274, 502, 194, 308, 194, 536, 502, 388, 354, 468, 776, 662],
  [548, 0, 684, 308, 194, 502, 730, 354, 696, 742, 1084, 594, 480, 674, 1016, 868, 1210],
  [776, 684, 0, 992, 878, 502, 274, 810, 468, 742, 400, 1278, 1164, 1130, 788, 1552, 754],
  [696, 308, 992, 0, 114, 650, 878, 502, 844, 890, 1232, 514, 628, 822, 1164, 560, 1358],
  [582, 194, 878, 114, 0, 536, 764, 388, 730, 776, 1118, 400, 514, 708, 1050, 674, 1244],
  [274, 502, 502, 650, 536, 0, 228, 308, 194, 240, 582, 776, 662, 628, 514, 1050, 708],
  [502, 730, 274, 878, 764, 228, 0, 536, 194, 468, 354, 1004, 890, 856, 514, 1278, 480],
  [194, 354, 810, 502, 388, 308, 536, 0, 342, 388, 730, 468, 354, 320, 662, 742, 856],
  [308, 696, 468, 844, 730, 194, 194, 342, 0, 274, 388, 810, 696, 662, 320, 1084, 514],
  [194, 742, 742, 890, 776, 240, 468, 388, 274, 0, 342, 536, 422, 388, 274, 810, 468],
  [536, 1084, 400, 1232, 1118, 582, 354, 730, 388, 342, 0, 878, 764, 730, 388, 1152, 354],
  [502, 594, 1278, 514, 400, 776, 1004, 468, 810, 536, 878, 0, 114, 308, 650, 274, 844],
  [388, 480, 1164, 628, 514, 662, 890, 354, 696, 422, 764, 114, 0, 194, 536, 388, 730],
  [354, 674, 1130, 822, 708, 628, 856, 320, 662, 388, 730, 308, 194, 0, 342, 422, 536],
  [468, 1016, 788, 1164, 1050, 514, 514, 662, 320, 274, 388, 650, 536, 342, 0, 764, 194],
  [776, 868, 1552, 560, 674, 1050, 1278, 742, 1084, 810, 1152, 274, 388, 422, 764, 0, 798],
  [662, 1210, 754, 1358, 1244, 708, 480, 856, 514, 468, 354, 844, 730, 536, 194, 798, 0]
]
data[:num_vehicles] = 4
data[:depot] = 0

# define the distance callback
manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

# add a distance dimension
dimension_name = "Distance"
routing.add_dimension(transit_callback_index, 0, 3000, true, dimension_name)
distance_dimension = routing.mutable_dimension(dimension_name)
distance_dimension.global_span_cost_coefficient = 100

# run the solver
solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

# print the solution
max_route_distance = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
  route_distance = 0
  while !routing.end?(index)
    plan_output += " #{manager.index_to_node(index)} -> "
    previous_index = index
    index = solution.value(routing.next_var(index))
    route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
  end
  plan_output += "#{manager.index_to_node(index)}\n"
  plan_output += "Distance of the route: #{route_distance}m\n\n"
  puts plan_output
  max_route_distance = [route_distance, max_route_distance].max
end
puts "Maximum of the route distances: #{max_route_distance}m"
```

### Capacity Constraints

[Guide](https://developers.google.com/optimization/routing/cvrp)

```ruby
data = {}
data[:distance_matrix] = [
  [0, 548, 776, 696, 582, 274, 502, 194, 308, 194, 536, 502, 388, 354, 468, 776, 662],
  [548, 0, 684, 308, 194, 502, 730, 354, 696, 742, 1084, 594, 480, 674, 1016, 868, 1210],
  [776, 684, 0, 992, 878, 502, 274, 810, 468, 742, 400, 1278, 1164, 1130, 788, 1552, 754],
  [696, 308, 992, 0, 114, 650, 878, 502, 844, 890, 1232, 514, 628, 822, 1164, 560, 1358],
  [582, 194, 878, 114, 0, 536, 764, 388, 730, 776, 1118, 400, 514, 708, 1050, 674, 1244],
  [274, 502, 502, 650, 536, 0, 228, 308, 194, 240, 582, 776, 662, 628, 514, 1050, 708],
  [502, 730, 274, 878, 764, 228, 0, 536, 194, 468, 354, 1004, 890, 856, 514, 1278, 480],
  [194, 354, 810, 502, 388, 308, 536, 0, 342, 388, 730, 468, 354, 320, 662, 742, 856],
  [308, 696, 468, 844, 730, 194, 194, 342, 0, 274, 388, 810, 696, 662, 320, 1084, 514],
  [194, 742, 742, 890, 776, 240, 468, 388, 274, 0, 342, 536, 422, 388, 274, 810, 468],
  [536, 1084, 400, 1232, 1118, 582, 354, 730, 388, 342, 0, 878, 764, 730, 388, 1152, 354],
  [502, 594, 1278, 514, 400, 776, 1004, 468, 810, 536, 878, 0, 114, 308, 650, 274, 844],
  [388, 480, 1164, 628, 514, 662, 890, 354, 696, 422, 764, 114, 0, 194, 536, 388, 730],
  [354, 674, 1130, 822, 708, 628, 856, 320, 662, 388, 730, 308, 194, 0, 342, 422, 536],
  [468, 1016, 788, 1164, 1050, 514, 514, 662, 320, 274, 388, 650, 536, 342, 0, 764, 194],
  [776, 868, 1552, 560, 674, 1050, 1278, 742, 1084, 810, 1152, 274, 388, 422, 764, 0, 798],
  [662, 1210, 754, 1358, 1244, 708, 480, 856, 514, 468, 354, 844, 730, 536, 194, 798, 0]
]
data[:demands] = [0, 1, 1, 2, 4, 2, 4, 8, 8, 1, 2, 1, 2, 4, 4, 8, 8]
data[:vehicle_capacities] = [15, 15, 15, 15]
data[:num_vehicles] = 4
data[:depot] = 0

manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)

routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

demand_callback = lambda do |from_index|
  from_node = manager.index_to_node(from_index)
  data[:demands][from_node]
end

demand_callback_index = routing.register_unary_transit_callback(demand_callback)
routing.add_dimension_with_vehicle_capacity(
  demand_callback_index,
  0,  # null capacity slack
  data[:vehicle_capacities],  # vehicle maximum capacities
  true,  # start cumul to zero
  "Capacity"
)

solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

total_distance = 0
total_load = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
  route_distance = 0
  route_load = 0
  while !routing.end?(index)
    node_index = manager.index_to_node(index)
    route_load += data[:demands][node_index]
    plan_output += " #{node_index} Load(#{route_load}) -> "
    previous_index = index
    index = solution.value(routing.next_var(index))
    route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
  end
  plan_output += " #{manager.index_to_node(index)} Load(#{route_load})\n"
  plan_output += "Distance of the route: #{route_distance}m\n"
  plan_output += "Load of the route: #{route_load}\n\n"
  puts plan_output
  total_distance += route_distance
  total_load += route_load
end
puts "Total distance of all routes: #{total_distance}m"
puts "Total load of all routes: #{total_load}"
```

### Pickups and Deliveries

[Guide](https://developers.google.com/optimization/routing/pickup_delivery)

```ruby
data = {}
data[:distance_matrix] = [
  [0, 548, 776, 696, 582, 274, 502, 194, 308, 194, 536, 502, 388, 354, 468, 776, 662],
  [548, 0, 684, 308, 194, 502, 730, 354, 696, 742, 1084, 594, 480, 674, 1016, 868, 1210],
  [776, 684, 0, 992, 878, 502, 274, 810, 468, 742, 400, 1278, 1164, 1130, 788, 1552, 754],
  [696, 308, 992, 0, 114, 650, 878, 502, 844, 890, 1232, 514, 628, 822, 1164, 560, 1358],
  [582, 194, 878, 114, 0, 536, 764, 388, 730, 776, 1118, 400, 514, 708, 1050, 674, 1244],
  [274, 502, 502, 650, 536, 0, 228, 308, 194, 240, 582, 776, 662, 628, 514, 1050, 708],
  [502, 730, 274, 878, 764, 228, 0, 536, 194, 468, 354, 1004, 890, 856, 514, 1278, 480],
  [194, 354, 810, 502, 388, 308, 536, 0, 342, 388, 730, 468, 354, 320, 662, 742, 856],
  [308, 696, 468, 844, 730, 194, 194, 342, 0, 274, 388, 810, 696, 662, 320, 1084, 514],
  [194, 742, 742, 890, 776, 240, 468, 388, 274, 0, 342, 536, 422, 388, 274, 810, 468],
  [536, 1084, 400, 1232, 1118, 582, 354, 730, 388, 342, 0, 878, 764, 730, 388, 1152, 354],
  [502, 594, 1278, 514, 400, 776, 1004, 468, 810, 536, 878, 0, 114, 308, 650, 274, 844],
  [388, 480, 1164, 628, 514, 662, 890, 354, 696, 422, 764, 114, 0, 194, 536, 388, 730],
  [354, 674, 1130, 822, 708, 628, 856, 320, 662, 388, 730, 308, 194, 0, 342, 422, 536],
  [468, 1016, 788, 1164, 1050, 514, 514, 662, 320, 274, 388, 650, 536, 342, 0, 764, 194],
  [776, 868, 1552, 560, 674, 1050, 1278, 742, 1084, 810, 1152, 274, 388, 422, 764, 0, 798],
  [662, 1210, 754, 1358, 1244, 708, 480, 856, 514, 468, 354, 844, 730, 536, 194, 798, 0]
]
data[:pickups_deliveries] = [
  [1, 6],
  [2, 10],
  [4, 3],
  [5, 9],
  [7, 8],
  [15, 11],
  [13, 12],
  [16, 14],
]
data[:num_vehicles] = 4
data[:depot] = 0

manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

dimension_name = "Distance"
routing.add_dimension(
  transit_callback_index,
  0,  # no slack
  3000,  # vehicle maximum travel distance
  true,  # start cumul to zero
  dimension_name
)
distance_dimension = routing.mutable_dimension(dimension_name)
distance_dimension.global_span_cost_coefficient = 100

data[:pickups_deliveries].each do |request|
  pickup_index = manager.node_to_index(request[0])
  delivery_index = manager.node_to_index(request[1])
  routing.add_pickup_and_delivery(pickup_index, delivery_index)
  routing.solver.add(routing.vehicle_var(pickup_index) == routing.vehicle_var(delivery_index))
  routing.solver.add(distance_dimension.cumul_var(pickup_index) <= distance_dimension.cumul_var(delivery_index))
end

solution = routing.solve(first_solution_strategy: :parallel_cheapest_insertion)

total_distance = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
  route_distance = 0
  while !routing.end?(index)
    plan_output += " #{manager.index_to_node(index)} -> "
    previous_index = index
    index = solution.value(routing.next_var(index))
    route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
  end
  plan_output += "#{manager.index_to_node(index)}\n"
  plan_output += "Distance of the route: #{route_distance}m\n\n"
  puts plan_output
  total_distance += route_distance
end
puts "Total Distance of all routes: #{total_distance}m"
```

### Time Window Constraints

[Guide](https://developers.google.com/optimization/routing/vrptw)

```ruby
data = {}
data[:time_matrix] = [
  [0, 6, 9, 8, 7, 3, 6, 2, 3, 2, 6, 6, 4, 4, 5, 9, 7],
  [6, 0, 8, 3, 2, 6, 8, 4, 8, 8, 13, 7, 5, 8, 12, 10, 14],
  [9, 8, 0, 11, 10, 6, 3, 9, 5, 8, 4, 15, 14, 13, 9, 18, 9],
  [8, 3, 11, 0, 1, 7, 10, 6, 10, 10, 14, 6, 7, 9, 14, 6, 16],
  [7, 2, 10, 1, 0, 6, 9, 4, 8, 9, 13, 4, 6, 8, 12, 8, 14],
  [3, 6, 6, 7, 6, 0, 2, 3, 2, 2, 7, 9, 7, 7, 6, 12, 8],
  [6, 8, 3, 10, 9, 2, 0, 6, 2, 5, 4, 12, 10, 10, 6, 15, 5],
  [2, 4, 9, 6, 4, 3, 6, 0, 4, 4, 8, 5, 4, 3, 7, 8, 10],
  [3, 8, 5, 10, 8, 2, 2, 4, 0, 3, 4, 9, 8, 7, 3, 13, 6],
  [2, 8, 8, 10, 9, 2, 5, 4, 3, 0, 4, 6, 5, 4, 3, 9, 5],
  [6, 13, 4, 14, 13, 7, 4, 8, 4, 4, 0, 10, 9, 8, 4, 13, 4],
  [6, 7, 15, 6, 4, 9, 12, 5, 9, 6, 10, 0, 1, 3, 7, 3, 10],
  [4, 5, 14, 7, 6, 7, 10, 4, 8, 5, 9, 1, 0, 2, 6, 4, 8],
  [4, 8, 13, 9, 8, 7, 10, 3, 7, 4, 8, 3, 2, 0, 4, 5, 6],
  [5, 12, 9, 14, 12, 6, 6, 7, 3, 3, 4, 7, 6, 4, 0, 9, 2],
  [9, 10, 18, 6, 8, 12, 15, 8, 13, 9, 13, 3, 4, 5, 9, 0, 9],
  [7, 14, 9, 16, 14, 8, 5, 10, 6, 5, 4, 10, 8, 6, 2, 9, 0],
]
data[:time_windows] = [
  [0, 5],  # depot
  [7, 12],  # 1
  [10, 15],  # 2
  [16, 18],  # 3
  [10, 13],  # 4
  [0, 5],  # 5
  [5, 10],  # 6
  [0, 4],  # 7
  [5, 10],  # 8
  [0, 3],  # 9
  [10, 16],  # 10
  [10, 15],  # 11
  [0, 5],  # 12
  [5, 10],  # 13
  [7, 8],  # 14
  [10, 15],  # 15
  [11, 15],  # 16
]
data[:num_vehicles] = 4
data[:depot] = 0

manager = ORTools::RoutingIndexManager.new(data[:time_matrix].size, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

time_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:time_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(time_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
time = "Time"
routing.add_dimension(
  transit_callback_index,
  30,  # allow waiting time
  30,  # maximum time per vehicle
  false,  # don't force start cumul to zero
  time
)
time_dimension = routing.mutable_dimension(time)

data[:time_windows].each_with_index do |time_window, location_idx|
  next if location_idx == 0
  index = manager.node_to_index(location_idx)
  time_dimension.cumul_var(index).set_range(time_window[0], time_window[1])
end

data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  time_dimension.cumul_var(index).set_range(data[:time_windows][0][0], data[:time_windows][0][1])
end

data[:num_vehicles].times do |i|
  routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.start(i)))
  routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.end(i)))
end

solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

time_dimension = routing.mutable_dimension("Time")
total_time = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
  while !routing.end?(index)
    time_var = time_dimension.cumul_var(index)
    plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)}) -> "
    index = solution.value(routing.next_var(index))
  end
  time_var = time_dimension.cumul_var(index)
  plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)})\n"
  plan_output += "Time of the route: #{solution.min(time_var)}min\n\n"
  puts plan_output
  total_time += solution.min(time_var)
end
puts "Total time of all routes: #{total_time}min"
```

### Resource Constraints

[Guide](https://developers.google.com/optimization/routing/cvrptw_resources)

```ruby
data = {}
data[:time_matrix] = [
  [0, 6, 9, 8, 7, 3, 6, 2, 3, 2, 6, 6, 4, 4, 5, 9, 7],
  [6, 0, 8, 3, 2, 6, 8, 4, 8, 8, 13, 7, 5, 8, 12, 10, 14],
  [9, 8, 0, 11, 10, 6, 3, 9, 5, 8, 4, 15, 14, 13, 9, 18, 9],
  [8, 3, 11, 0, 1, 7, 10, 6, 10, 10, 14, 6, 7, 9, 14, 6, 16],
  [7, 2, 10, 1, 0, 6, 9, 4, 8, 9, 13, 4, 6, 8, 12, 8, 14],
  [3, 6, 6, 7, 6, 0, 2, 3, 2, 2, 7, 9, 7, 7, 6, 12, 8],
  [6, 8, 3, 10, 9, 2, 0, 6, 2, 5, 4, 12, 10, 10, 6, 15, 5],
  [2, 4, 9, 6, 4, 3, 6, 0, 4, 4, 8, 5, 4, 3, 7, 8, 10],
  [3, 8, 5, 10, 8, 2, 2, 4, 0, 3, 4, 9, 8, 7, 3, 13, 6],
  [2, 8, 8, 10, 9, 2, 5, 4, 3, 0, 4, 6, 5, 4, 3, 9, 5],
  [6, 13, 4, 14, 13, 7, 4, 8, 4, 4, 0, 10, 9, 8, 4, 13, 4],
  [6, 7, 15, 6, 4, 9, 12, 5, 9, 6, 10, 0, 1, 3, 7, 3, 10],
  [4, 5, 14, 7, 6, 7, 10, 4, 8, 5, 9, 1, 0, 2, 6, 4, 8],
  [4, 8, 13, 9, 8, 7, 10, 3, 7, 4, 8, 3, 2, 0, 4, 5, 6],
  [5, 12, 9, 14, 12, 6, 6, 7, 3, 3, 4, 7, 6, 4, 0, 9, 2],
  [9, 10, 18, 6, 8, 12, 15, 8, 13, 9, 13, 3, 4, 5, 9, 0, 9],
  [7, 14, 9, 16, 14, 8, 5, 10, 6, 5, 4, 10, 8, 6, 2, 9, 0]
]
data[:time_windows] = [
  [0, 5],  # depot
  [7, 12],  # 1
  [10, 15],  # 2
  [5, 14],  # 3
  [5, 13],  # 4
  [0, 5],  # 5
  [5, 10],  # 6
  [0, 10],  # 7
  [5, 10],  # 8
  [0, 5],  # 9
  [10, 16],  # 10
  [10, 15],  # 11
  [0, 5],  # 12
  [5, 10],  # 13
  [7, 12],  # 14
  [10, 15],  # 15
  [5, 15],  # 16
]
data[:num_vehicles] = 4
data[:vehicle_load_time] = 5
data[:vehicle_unload_time] = 5
data[:depot_capacity] = 2
data[:depot] = 0

manager = ORTools::RoutingIndexManager.new(data[:time_matrix].size, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

time_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:time_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(time_callback)

routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

time = "Time"
routing.add_dimension(
  transit_callback_index,
  60,  # allow waiting time
  60,  # maximum time per vehicle
  false,  # don't force start cumul to zero
  time
)
time_dimension = routing.mutable_dimension(time)
data[:time_windows].each_with_index do |time_window, location_idx|
  next if location_idx == 0
  index = manager.node_to_index(location_idx)
  time_dimension.cumul_var(index).set_range(time_window[0], time_window[1])
end

data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  time_dimension.cumul_var(index).set_range(data[:time_windows][0][0], data[:time_windows][0][1])
end

solver = routing.solver
intervals = []
data[:num_vehicles].times do |i|
  intervals << solver.fixed_duration_interval_var(
    time_dimension.cumul_var(routing.start(i)),
    data[:vehicle_load_time],
    "depot_interval"
  )
  intervals << solver.fixed_duration_interval_var(
    time_dimension.cumul_var(routing.end(i)),
    data[:vehicle_unload_time],
    "depot_interval"
  )
end

depot_usage = [1] * intervals.size
solver.add(solver.cumulative(intervals, depot_usage, data[:depot_capacity], "depot"))

data[:num_vehicles].times do |i|
  routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.start(i)))
  routing.add_variable_minimized_by_finalizer(time_dimension.cumul_var(routing.end(i)))
end

solution = routing.solve(first_solution_strategy: :path_cheapest_arc)

time_dimension = routing.mutable_dimension("Time")
total_time = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = String.new("Route for vehicle #{vehicle_id}:\n")
  while !routing.end?(index)
    time_var = time_dimension.cumul_var(index)
    plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)}) -> "
    index = solution.value(routing.next_var(index))
  end
  time_var = time_dimension.cumul_var(index)
  plan_output += "#{manager.index_to_node(index)} Time(#{solution.min(time_var)},#{solution.max(time_var)})\n"
  plan_output += "Time of the route: #{solution.min(time_var)}min\n\n"
  puts plan_output
  total_time += solution.min(time_var)
end
puts "Total time of all routes: #{total_time}min"
```

### Penalties and Dropping Visits

[Guide](https://developers.google.com/optimization/routing/penalties)

```ruby
data = {}
data[:distance_matrix] = [
  [0, 548, 776, 696, 582, 274, 502, 194, 308, 194, 536, 502, 388, 354, 468, 776, 662],
  [548, 0, 684, 308, 194, 502, 730, 354, 696, 742, 1084, 594, 480, 674, 1016, 868, 1210],
  [776, 684, 0, 992, 878, 502, 274, 810, 468, 742, 400, 1278, 1164, 1130, 788, 1552, 754],
  [696, 308, 992, 0, 114, 650, 878, 502, 844, 890, 1232, 514, 628, 822, 1164, 560, 1358],
  [582, 194, 878, 114, 0, 536, 764, 388, 730, 776, 1118, 400, 514, 708, 1050, 674, 1244],
  [274, 502, 502, 650, 536, 0, 228, 308, 194, 240, 582, 776, 662, 628, 514, 1050, 708],
  [502, 730, 274, 878, 764, 228, 0, 536, 194, 468, 354, 1004, 890, 856, 514, 1278, 480],
  [194, 354, 810, 502, 388, 308, 536, 0, 342, 388, 730, 468, 354, 320, 662, 742, 856],
  [308, 696, 468, 844, 730, 194, 194, 342, 0, 274, 388, 810, 696, 662, 320, 1084, 514],
  [194, 742, 742, 890, 776, 240, 468, 388, 274, 0, 342, 536, 422, 388, 274, 810, 468],
  [536, 1084, 400, 1232, 1118, 582, 354, 730, 388, 342, 0, 878, 764, 730, 388, 1152, 354],
  [502, 594, 1278, 514, 400, 776, 1004, 468, 810, 536, 878, 0, 114, 308, 650, 274, 844],
  [388, 480, 1164, 628, 514, 662, 890, 354, 696, 422, 764, 114, 0, 194, 536, 388, 730],
  [354, 674, 1130, 822, 708, 628, 856, 320, 662, 388, 730, 308, 194, 0, 342, 422, 536],
  [468, 1016, 788, 1164, 1050, 514, 514, 662, 320, 274, 388, 650, 536, 342, 0, 764, 194],
  [776, 868, 1552, 560, 674, 1050, 1278, 742, 1084, 810, 1152, 274, 388, 422, 764, 0, 798],
  [662, 1210, 754, 1358, 1244, 708, 480, 856, 514, 468, 354, 844, 730, 536, 194, 798, 0]
]
data[:demands] = [0, 1, 1, 3, 6, 3, 6, 8, 8, 1, 2, 1, 2, 6, 6, 8, 8]
data[:vehicle_capacities] = [15, 15, 15, 15]
data[:num_vehicles] = 4
data[:depot] = 0

manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].size, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)

routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)

demand_callback = lambda do |from_index|
  from_node = manager.index_to_node(from_index)
  data[:demands][from_node]
end

demand_callback_index = routing.register_unary_transit_callback(demand_callback)
routing.add_dimension_with_vehicle_capacity(
  demand_callback_index,
  0,  # null capacity slack
  data[:vehicle_capacities],  # vehicle maximum capacities
  true,  # start cumul to zero
  "Capacity"
)

penalty = 1000
1.upto(data[:distance_matrix].size - 1) do |node|
  routing.add_disjunction([manager.node_to_index(node)], penalty)
end

assignment = routing.solve(first_solution_strategy: :path_cheapest_arc)

dropped_nodes = String.new("Dropped nodes:")
routing.size.times do |node|
  next if routing.start?(node) || routing.end?(node)

  if assignment.value(routing.next_var(node)) == node
    dropped_nodes += " #{manager.index_to_node(node)}"
  end
end
puts dropped_nodes

total_distance = 0
total_load = 0
data[:num_vehicles].times do |vehicle_id|
  index = routing.start(vehicle_id)
  plan_output = "Route for vehicle #{vehicle_id}:\n"
  route_distance = 0
  route_load = 0
  while !routing.end?(index)
    node_index = manager.index_to_node(index)
    route_load += data[:demands][node_index]
    plan_output += " #{node_index} Load(#{route_load}) -> "
    previous_index = index
    index = assignment.value(routing.next_var(index))
    route_distance += routing.arc_cost_for_vehicle(previous_index, index, vehicle_id)
  end
  plan_output += " #{manager.index_to_node(index)} Load(#{route_load})\n"
  plan_output += "Distance of the route: #{route_distance}m\n"
  plan_output += "Load of the route: #{route_load}\n\n"
  puts plan_output
  total_distance += route_distance
  total_load += route_load
end
puts "Total Distance of all routes: #{total_distance}m"
puts "Total Load of all routes: #{total_load}"
```

### Routing Options

[Guide](https://developers.google.com/optimization/routing/routing_options)

```ruby
routing.solve(
  solution_limit: 10,
  time_limit: 10, # seconds,
  lns_time_limit: 10, # seconds
  first_solution_strategy: :path_cheapest_arc,
  local_search_metaheuristic: :guided_local_search,
  log_search: true
)
```

### The Knapsack Problem

[Guide](https://developers.google.com/optimization/bin/knapsack)

```ruby
# create the data
values = [
  360, 83, 59, 130, 431, 67, 230, 52, 93, 125, 670, 892, 600, 38, 48, 147,
  78, 256, 63, 17, 120, 164, 432, 35, 92, 110, 22, 42, 50, 323, 514, 28,
  87, 73, 78, 15, 26, 78, 210, 36, 85, 189, 274, 43, 33, 10, 19, 389, 276,
  312
]
weights = [[
  7, 0, 30, 22, 80, 94, 11, 81, 70, 64, 59, 18, 0, 36, 3, 8, 15, 42, 9, 0,
  42, 47, 52, 32, 26, 48, 55, 6, 29, 84, 2, 4, 18, 56, 7, 29, 93, 44, 71,
  3, 86, 66, 31, 65, 0, 79, 20, 65, 52, 13
]]
capacities = [850]

# declare the solver
solver = ORTools::KnapsackSolver.new(:branch_and_bound, "KnapsackExample")

# call the solver
solver.init(values, weights, capacities)
computed_value = solver.solve

packed_items = []
packed_weights = []
total_weight = 0
puts "Total value = #{computed_value}"
values.length.times do |i|
  if solver.best_solution_contains?(i)
    packed_items << i
    packed_weights << weights[0][i]
    total_weight += weights[0][i]
  end
end
puts "Total weight: #{total_weight}"
puts "Packed items: #{packed_items}"
puts "Packed weights: #{packed_weights}"
```

### Multiple Knapsacks

[Guide](https://developers.google.com/optimization/bin/multiple_knapsack)

```ruby
# create the data
data = {}
weights = [48, 30, 42, 36, 36, 48, 42, 42, 36, 24, 30, 30, 42, 36, 36]
values = [10, 30, 25, 50, 35, 30, 15, 40, 30, 35, 45, 10, 20, 30, 25]
data[:weights] = weights
data[:values] = values
data[:items] = (0...weights.length).to_a
data[:num_items] = weights.length
num_bins = 5
data[:bins] = (0...num_bins).to_a
data[:bin_capacities] = [100, 100, 100, 100, 100]

# declare the solver
solver = ORTools::Solver.new("simple_mip_program", :cbc)

# create the variables
# x[i, j] = 1 if item i is packed in bin j
x = {}
data[:items].each do |i|
  data[:bins].each do |j|
    x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
  end
end

# define the constraints
# each item can be in at most one bin
data[:items].each do |i|
  sum = ORTools::LinearExpr.new
  data[:bins].each do |j|
    sum += x[[i, j]]
  end
  solver.add(sum <= 1.0)
end

# the amount packed in each bin cannot exceed its capacity
data[:bins].each do |j|
  weight = ORTools::LinearExpr.new
  data[:items].each do |i|
    weight += x[[i, j]] * data[:weights][i]
  end
  solver.add(weight <= data[:bin_capacities][j])
end

# define the objective
objective = solver.objective

data[:items].each do |i|
  data[:bins].each do |j|
    objective.set_coefficient(x[[i, j]], data[:values][i])
  end
end
objective.set_maximization

# call the solver and print the solution
status = solver.solve

if status == :optimal
  puts "Total packed value: #{objective.value}"
  total_weight = 0
  data[:bins].each do |j|
    bin_weight = 0
    bin_value = 0
    puts "Bin  #{j}\n\n"
    data[:items].each do |i|
      if x[[i, j]].solution_value > 0
        puts "Item #{i} - weight: #{data[:weights][i]}  value: #{data[:values][i]}"
        bin_weight += data[:weights][i]
        bin_value += data[:values][i]
      end
    end
    puts "Packed bin weight: #{bin_weight}"
    puts "Packed bin value: #{bin_value}"
    puts
    total_weight += bin_weight
  end
  puts "Total packed weight: #{total_weight}"
else
  puts "The problem does not have an optimal solution."
end
```

### Bin Packing Problem

[Guide](https://developers.google.com/optimization/bin/bin_packing)

```ruby
# create the data
data = {}
weights = [48, 30, 19, 36, 36, 27, 42, 42, 36, 24, 30]
data[:weights] = weights
data[:items] = (0...weights.length).to_a
data[:bins] = data[:items]
data[:bin_capacity] = 100

# create the mip solver with the CBC backend
solver = ORTools::Solver.new("simple_mip_program", :cbc)

# variables
# x[i, j] = 1 if item i is packed in bin j
x = {}
data[:items].each do |i|
  data[:bins].each do |j|
    x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
  end
end

# y[j] = 1 if bin j is used
y = {}
data[:bins].each do |j|
  y[j] = solver.int_var(0, 1, "y[%i]" % j)
end

# constraints
# each item must be in exactly one bin
data[:items].each do |i|
  solver.add(solver.sum(data[:bins].map { |j| x[[i, j]] }) == 1)
end

# the amount packed in each bin cannot exceed its capacity
data[:bins].each do |j|
  sum = solver.sum(data[:items].map { |i| x[[i, j]] * data[:weights][i] })
  solver.add(sum <= y[j] * data[:bin_capacity])
end

# objective: minimize the number of bins used
solver.minimize(solver.sum(data[:bins].map { |j| y[j] }))

# call the solver and print the solution
if status == :optimal
  num_bins = 0
  data[:bins].each do |j|
    if y[j].solution_value == 1
      bin_items = []
      bin_weight = 0
      data[:items].each do |i|
        if x[[i, j]].solution_value > 0
          bin_items << i
          bin_weight += data[:weights][i]
        end
      end
      if bin_weight > 0
        num_bins += 1
        puts "Bin number #{j}"
        puts "  Items packed: #{bin_items}"
        puts "  Total weight: #{bin_weight}"
        puts
      end
    end
  end
  puts
  puts "Number of bins used: #{num_bins}"
  puts "Time = #{solver.wall_time} milliseconds"
else
  puts "The problem does not have an optimal solution."
end
```

### Maximum Flows

[Guide](https://developers.google.com/optimization/flow/maxflow)

```ruby
# define the data
start_nodes = [0, 0, 0, 1, 1, 2, 2, 3, 3]
end_nodes = [1, 2, 3, 2, 4, 3, 4, 2, 4]
capacities = [20, 30, 10, 40, 30, 10, 20, 5, 20]

# declare the solver and add the arcs
max_flow = ORTools::SimpleMaxFlow.new

start_nodes.length.times do |i|
  max_flow.add_arc_with_capacity(start_nodes[i], end_nodes[i], capacities[i])
end

# invoke the solver and display the results
if max_flow.solve(0, 4) == :optimal
  puts "Max flow: #{max_flow.optimal_flow}"
  puts
  puts "  Arc    Flow / Capacity"
  max_flow.num_arcs.times do |i|
    puts "%1s -> %1s   %3s  / %3s" % [
      max_flow.tail(i),
      max_flow.head(i),
      max_flow.flow(i),
      max_flow.capacity(i)
    ]
  end
  puts "Source side min-cut: #{max_flow.source_side_min_cut}"
  puts "Sink side min-cut: #{max_flow.sink_side_min_cut}"
else
  puts "There was an issue with the max flow input."
end
```

### Minimum Cost Flows

[Guide](https://developers.google.com/optimization/flow/mincostflow)

```ruby
# define the data
start_nodes = [ 0, 0,  1, 1,  1,  2, 2,  3, 4]
end_nodes   = [ 1, 2,  2, 3,  4,  3, 4,  4, 2]
capacities  = [15, 8, 20, 4, 10, 15, 4, 20, 5]
unit_costs  = [ 4, 4,  2, 2,  6,  1, 3,  2, 3]
supplies = [20, 0, 0, -5, -15]

# declare the solver and add the arcs
min_cost_flow = ORTools::SimpleMinCostFlow.new

start_nodes.length.times do |i|
  min_cost_flow.add_arc_with_capacity_and_unit_cost(
    start_nodes[i], end_nodes[i], capacities[i], unit_costs[i]
  )
end

supplies.length.times do |i|
  min_cost_flow.set_node_supply(i, supplies[i])
end

# invoke the solver and display the results
if min_cost_flow.solve == :optimal
  puts "Minimum cost #{min_cost_flow.optimal_cost}"
  puts
  puts "  Arc    Flow / Capacity  Cost"
  min_cost_flow.num_arcs.times do |i|
    cost = min_cost_flow.flow(i) * min_cost_flow.unit_cost(i)
    puts "%1s -> %1s   %3s  / %3s       %3s" % [
      min_cost_flow.tail(i),
      min_cost_flow.head(i),
      min_cost_flow.flow(i),
      min_cost_flow.capacity(i),
      cost
    ]
  end
else
  puts "There was an issue with the min cost flow input."
end
```

### Assignment as a Min Cost Flow Problem

[Guide](https://developers.google.com/optimization/assignment/assignment_min_cost_flow)

```ruby
# create the solver
min_cost_flow = ORTools::SimpleMinCostFlow.new

# create the data
start_nodes = [0, 0, 0, 0] + [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4] + [5, 6, 7, 8]
end_nodes = [1, 2, 3, 4] + [5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8] + [9, 9, 9, 9]
capacities = [1, 1, 1, 1] + [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] + [1, 1, 1, 1]
costs = [0, 0, 0, 0] + [90, 76, 75, 70, 35, 85, 55, 65, 125, 95, 90, 105, 45, 110, 95, 115] + [0, 0, 0, 0]
supplies = [4, 0, 0, 0, 0, 0, 0, 0, 0, -4]
source = 0
sink = 9
tasks = 4

# create the graph and constraints
start_nodes.length.times do |i|
  min_cost_flow.add_arc_with_capacity_and_unit_cost(
    start_nodes[i], end_nodes[i], capacities[i], costs[i]
  )
end

supplies.length.times do |i|
  min_cost_flow.set_node_supply(i, supplies[i])
end

# invoke the solver
if min_cost_flow.solve == :optimal
  puts "Total cost = #{min_cost_flow.optimal_cost}"
  puts
  min_cost_flow.num_arcs.times do |arc|
    if min_cost_flow.tail(arc) != source && min_cost_flow.head(arc) != sink
      if min_cost_flow.flow(arc) > 0
        puts "Worker %d assigned to task %d.  Cost = %d" % [
          min_cost_flow.tail(arc),
          min_cost_flow.head(arc),
          min_cost_flow.unit_cost(arc)
        ]
      end
    end
  end
else
  puts "There was an issue with the min cost flow input."
end
```

### Employee Scheduling

[Guide](https://developers.google.com/optimization/scheduling/employee_scheduling)

```ruby
# define the data
num_nurses = 4
num_shifts = 3
num_days = 3
all_nurses = num_nurses.times.to_a
all_shifts = num_shifts.times.to_a
all_days = num_days.times.to_a

# create the variables
model = ORTools::CpModel.new

shifts = {}
all_nurses.each do |n|
  all_days.each do |d|
    all_shifts.each do |s|
      shifts[[n, d, s]] = model.new_bool_var("shift_n%id%is%i" % [n, d, s])
    end
  end
end

# assign nurses to shifts
all_days.each do |d|
  all_shifts.each do |s|
    model.add(model.sum(all_nurses.map { |n| shifts[[n, d, s]] }) == 1)
  end
end

all_nurses.each do |n|
  all_days.each do |d|
    model.add(model.sum(all_shifts.map { |s| shifts[[n, d, s]] }) <= 1)
  end
end

# assign shifts evenly
min_shifts_per_nurse = (num_shifts * num_days) / num_nurses
max_shifts_per_nurse = min_shifts_per_nurse + 1
all_nurses.each do |n|
  num_shifts_worked = model.sum(all_days.flat_map { |d| all_shifts.map { |s| shifts[[n, d, s]] } })
  model.add(num_shifts_worked >= min_shifts_per_nurse)
  model.add(num_shifts_worked <= max_shifts_per_nurse)
end

# create a printer
class NursesPartialSolutionPrinter < ORTools::CpSolverSolutionCallback
  attr_reader :solution_count

  def initialize(shifts, num_nurses, num_days, num_shifts, sols)
    super()
    @shifts = shifts
    @num_nurses = num_nurses
    @num_days = num_days
    @num_shifts = num_shifts
    @solutions = sols
    @solution_count = 0
  end

  def on_solution_callback
    if @solutions.include?(@solution_count)
      puts "Solution #{@solution_count}"
      @num_days.times do |d|
        puts "Day #{d}"
        @num_nurses.times do |n|
          working = false
          @num_shifts.times do |s|
            if value(@shifts[[n, d, s]])
              working = true
              puts "  Nurse %i works shift %i" % [n, s]
            end
          end
          unless working
            puts "  Nurse #{n} does not work"
          end
        end
      end
      puts
    end
    @solution_count += 1
  end
end

# call the solver and display the results
solver = ORTools::CpSolver.new
a_few_solutions = 5.times.to_a
solution_printer = NursesPartialSolutionPrinter.new(
  shifts, num_nurses, num_days, num_shifts, a_few_solutions
)
solver.search_for_all_solutions(model, solution_printer)

puts
puts "Statistics"
puts "  - conflicts       : %i" % solver.num_conflicts
puts "  - branches        : %i" % solver.num_branches
puts "  - wall time       : %f s" % solver.wall_time
puts "  - solutions found : %i" % solution_printer.solution_count
```

### The Job Shop Problem

[Guide](https://developers.google.com/optimization/scheduling/job_shop)

```ruby
# create the model
model = ORTools::CpModel.new

jobs_data = [
  [[0, 3], [1, 2], [2, 2]],
  [[0, 2], [2, 1], [1, 4]],
  [[1, 4], [2, 3]]
]

machines_count = 1 + jobs_data.flat_map { |job| job.map { |task| task[0] }  }.max
all_machines = machines_count.times.to_a

# computes horizon dynamically as the sum of all durations
horizon = jobs_data.flat_map { |job| job.map { |task| task[1] }  }.sum

# creates job intervals and add to the corresponding machine lists
all_tasks = {}
machine_to_intervals = Hash.new { |hash, key| hash[key] = [] }

jobs_data.each_with_index do |job, job_id|
  job.each_with_index do |task, task_id|
    machine = task[0]
    duration = task[1]
    suffix = "_%i_%i" % [job_id, task_id]
    start_var = model.new_int_var(0, horizon, "start" + suffix)
    duration_var = model.new_int_var(duration, duration, "duration" + suffix)
    end_var = model.new_int_var(0, horizon, "end" + suffix)
    interval_var = model.new_interval_var(start_var, duration_var, end_var, "interval" + suffix)
    all_tasks[[job_id, task_id]] = {start: start_var, end: end_var, interval: interval_var}
    machine_to_intervals[machine] << interval_var
  end
end

# create and add disjunctive constraints
all_machines.each do |machine|
  model.add_no_overlap(machine_to_intervals[machine])
end

# precedences inside a job
jobs_data.each_with_index do |job, job_id|
  (job.size - 1).times do |task_id|
    model.add(all_tasks[[job_id, task_id + 1]][:start] >= all_tasks[[job_id, task_id]][:end])
  end
end

# makespan objective
obj_var = model.new_int_var(0, horizon, "makespan")
model.add_max_equality(obj_var, jobs_data.map.with_index { |job, job_id| all_tasks[[job_id, job.size - 1]][:end] })
model.minimize(obj_var)

# solve model
solver = ORTools::CpSolver.new
status = solver.solve(model)

# create one list of assigned tasks per machine
assigned_jobs = Hash.new { |hash, key| hash[key] = [] }
jobs_data.each_with_index do |job, job_id|
  job.each_with_index do |task, task_id|
    machine = task[0]
    assigned_jobs[machine] << {
      start: solver.value(all_tasks[[job_id, task_id]][:start]),
      job: job_id,
      index: task_id,
      duration: task[1]
    }
  end
end

# create per machine output lines
output = String.new("")
all_machines.each do |machine|
  # sort by starting time
  assigned_jobs[machine].sort_by! { |v| v[:start] }
  sol_line_tasks = "Machine #{machine}: "
  sol_line = "           "

  assigned_jobs[machine].each do |assigned_task|
    name = "job_%i_%i" % [assigned_task[:job], assigned_task[:index]]
    # add spaces to output to align columns
    sol_line_tasks += "%-10s" % name
    start = assigned_task[:start]
    duration = assigned_task[:duration]
    sol_tmp = "[%i,%i]" % [start, start + duration]
    # add spaces to output to align columns
    sol_line += "%-10s" % sol_tmp
  end

  sol_line += "\n"
  sol_line_tasks += "\n"
  output += sol_line_tasks
  output += sol_line
end

# finally print the solution found
puts "Optimal Schedule Length: %i" % solver.objective_value
puts output
```

### Sudoku

[Example](https://github.com/google/or-tools/blob/stable/examples/python/sudoku_sat.py)

```ruby
# create the model
model = ORTools::CpModel.new

cell_size = 3
line_size = cell_size**2
line = (0...line_size).to_a
cell = (0...cell_size).to_a

initial_grid = [
  [0, 6, 0, 0, 5, 0, 0, 2, 0],
  [0, 0, 0, 3, 0, 0, 0, 9, 0],
  [7, 0, 0, 6, 0, 0, 0, 1, 0],
  [0, 0, 6, 0, 3, 0, 4, 0, 0],
  [0, 0, 4, 0, 7, 0, 1, 0, 0],
  [0, 0, 5, 0, 9, 0, 8, 0, 0],
  [0, 4, 0, 0, 0, 1, 0, 0, 6],
  [0, 3, 0, 0, 0, 8, 0, 0, 0],
  [0, 2, 0, 0, 4, 0, 0, 5, 0]
]

grid = {}
line.each do |i|
  line.each do |j|
    grid[[i, j]] = model.new_int_var(1, line_size, "grid %i %i" % [i, j])
  end
end

# all different on rows
line.each do |i|
  model.add_all_different(line.map { |j| grid[[i, j]] })
end

# all different on columns
line.each do |j|
  model.add_all_different(line.map { |i| grid[[i, j]] })
end

# all different on cells
cell.each do |i|
  cell.each do |j|
    one_cell = []
    cell.each do |di|
      cell.each do |dj|
        one_cell << grid[[i * cell_size + di, j * cell_size + dj]]
      end
    end
    model.add_all_different(one_cell)
  end
end

# initial values
line.each do |i|
  line.each do |j|
    if initial_grid[i][j] != 0
      model.add(grid[[i, j]] == initial_grid[i][j])
    end
  end
end

# solve and print solution
solver = ORTools::CpSolver.new
status = solver.solve(model)
if status == :optimal
  line.each do |i|
    p line.map { |j| solver.value(grid[[i, j]]) }
  end
end
```

### Wedding Seating Chart

[Example](https://github.com/google/or-tools/blob/stable/examples/python/wedding_optimal_chart_sat.py)

```ruby
# From
# Meghan L. Bellows and J. D. Luc Peterson
# "Finding an optimal seating chart for a wedding"
# https://www.improbable.com/news/2012/Optimal-seating-chart.pdf
# https://www.improbable.com/2012/02/12/finding-an-optimal-seating-chart-for-a-wedding
#
# Every year, millions of brides (not to mention their mothers, future
# mothers-in-law, and occasionally grooms) struggle with one of the
# most daunting tasks during the wedding-planning process: the
# seating chart. The guest responses are in, banquet hall is booked,
# menu choices have been made. You think the hard parts are over,
# but you have yet to embark upon the biggest headache of them all.
# In order to make this process easier, we present a mathematical
# formulation that models the seating chart problem. This model can
# be solved to find the optimal arrangement of guests at tables.
# At the very least, it can provide a starting point and hopefully
# minimize stress and arguments.
#
# Adapted from
# https://github.com/google/or-tools/blob/stable/examples/python/wedding_optimal_chart_sat.py

# Easy problem (from the paper)
# num_tables = 2
# table_capacity = 10
# min_known_neighbors = 1

# Slightly harder problem (also from the paper)
num_tables = 5
table_capacity = 4
min_known_neighbors = 1

# Connection matrix: who knows who, and how strong
# is the relation
c = [
  [1, 50, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [50, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 1, 50, 1, 1, 1, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 50, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 1, 1, 1, 50, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 1, 1, 50, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 1, 1, 1, 1, 1, 50, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 1, 1, 1, 1, 50, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [1, 1, 10, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 50, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1]
]

# Names of the guests. B: Bride side, G: Groom side
names = [
  "Deb (B)", "John (B)", "Martha (B)", "Travis (B)", "Allan (B)",
  "Lois (B)", "Jayne (B)", "Brad (B)", "Abby (B)", "Mary Helen (G)",
  "Lee (G)", "Annika (G)", "Carl (G)", "Colin (G)", "Shirley (G)",
  "DeAnn (G)", "Lori (G)"
]

num_guests = c.size

all_tables = num_tables.times.to_a
all_guests = num_guests.times.to_a

# create the cp model
model = ORTools::CpModel.new

# decision variables
seats = {}
all_tables.each do |t|
  all_guests.each do |g|
    seats[[t, g]] = model.new_bool_var("guest %i seats on table %i" % [g, t])
  end
end

pairs = all_guests.combination(2)

colocated = {}
pairs.each do |g1, g2|
  colocated[[g1, g2]] = model.new_bool_var("guest %i seats with guest %i" % [g1, g2])
end

same_table = {}
pairs.each do |g1, g2|
  all_tables.each do |t|
    same_table[[g1, g2, t]] = model.new_bool_var("guest %i seats with guest %i on table %i" % [g1, g2, t])
  end
end

# Objective
model.maximize(model.sum((num_guests - 1).times.flat_map { |g1| (g1 + 1).upto(num_guests - 1).select { |g2| c[g1][g2] > 0 }.map { |g2| colocated[[g1, g2]] * c[g1][g2] } }))

#
# Constraints
#

# Everybody seats at one table.
all_guests.each do |g|
  model.add(model.sum(all_tables.map { |t| seats[[t, g]] }) == 1)
end

# Tables have a max capacity.
all_tables.each do |t|
  model.add(model.sum(all_guests.map { |g| seats[[t, g]] }) <= table_capacity)
end

# Link colocated with seats
pairs.each do |g1, g2|
  all_tables.each do |t|
    # Link same_table and seats.
    model.add_bool_or([seats[[t, g1]].not, seats[[t, g2]].not, same_table[[g1, g2, t]]])
    model.add_implication(same_table[[g1, g2, t]], seats[[t, g1]])
    model.add_implication(same_table[[g1, g2, t]], seats[[t, g2]])
  end

  # Link colocated and same_table.
  model.add(model.sum(all_tables.map { |t| same_table[[g1, g2, t]] }) == colocated[[g1, g2]])
end

# Min known neighbors rule.
all_guests.each do |g|
  model.add(
    model.sum(
      (g + 1).upto(num_guests - 1).
      select { |g2| c[g][g2] > 0 }.
      product(all_tables).
      map { |g2, t| same_table[[g, g2, t]] }
    ) +
    model.sum(
      g.times.
      select { |g1| c[g1][g] > 0 }.
      product(all_tables).
      map { |g1, t| same_table[[g1, g, t]] }
    ) >= min_known_neighbors
  )
end

# Symmetry breaking. First guest seats on the first table.
model.add(seats[[0, 0]] == 1)

# Solve model
solver = ORTools::CpSolver.new
solution_printer = WeddingChartPrinter.new(seats, names, num_tables, num_guests)
solver.solve_with_solution_callback(model, solution_printer)

puts "Statistics"
puts "  - conflicts    : %i" % solver.num_conflicts
puts "  - branches     : %i" % solver.num_branches
puts "  - wall time    : %f s" % solver.wall_time
puts "  - num solutions: %i" % solution_printer.num_solutions
```

### Set Partitioning

[Example](https://pythonhosted.org/PuLP/CaseStudies/a_set_partitioning_problem.html)

```ruby
# A set partitioning model of a wedding seating problem
# Authors: Stuart Mitchell 2009

max_tables = 5
max_table_size = 4
guests = %w(A B C D E F G I J K L M N O P Q R)

# Find the happiness of the table
# by calculating the maximum distance between the letters
def happiness(table)
  (table[0].ord - table[-1].ord).abs
end

# create list of all possible tables
possible_tables = []
(1..max_table_size).each do |i|
  possible_tables += guests.combination(i).to_a
end

solver = ORTools::Solver.new("Wedding Seating Model", :cbc)

# create a binary variable to state that a table setting is used
x = {}
possible_tables.each do |table|
  x[table] = solver.int_var(0, 1, "table #{table.join(", ")}")
end

solver.minimize(solver.sum(possible_tables.map { |table| x[table] * happiness(table) }))

# specify the maximum number of tables
solver.add(solver.sum(x.values) <= max_tables)

# a guest must seated at one and only one table
guests.each do |guest|
  tables_with_guest = possible_tables.select { |table| table.include?(guest) }
  solver.add(solver.sum(tables_with_guest.map { |table| x[table] }) == 1)
end

status = solver.solve

puts "The chosen tables are out of a total of %s:" % possible_tables.size
possible_tables.each do |table|
  if x[table].solution_value == 1
    p table
  end
end
```

## History

View the [changelog](https://github.com/ankane/or-tools/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/or-tools/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/or-tools/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/or-tools.git
cd or-tools
bundle install
bundle exec rake compile
bundle exec rake test
```

Resources

- [OR-Tools Reference](https://developers.google.com/optimization/reference)
