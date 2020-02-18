# OR-Tools

[OR-Tools](https://github.com/google/or-tools) - operations research tools - for Ruby

[![Build Status](https://travis-ci.org/ankane/or-tools.svg?branch=master)](https://travis-ci.org/ankane/or-tools)

## Installation

Download the [OR-Tools C++ library](https://developers.google.com/optimization/install/cpp). Then run:

```sh
bundle config build.or-tools --with-or-tools-dir=/path/to/or-tools
```

Add this line to your application’s Gemfile:

```ruby
gem 'or-tools'
```

## Getting Started

Linear Optimization

- [The Glop Linear Solver](#the-glop-linear-solver)

Constraint Optimization

- [CP-SAT Solver](#cp-sat-solver)
- [Solving an Optimization Problem](#solving-an-optimization-problem)

Integer Optimization

- [Mixed-Integer Programming](#mixed-integer-programming)

Routing

- [Traveling Salesperson Problem (TSP)](#traveling-salesperson-problem-tsp)
- [Vehicle Routing Problem (VRP)](#vehicle-routing-problem-vrp)
- [Routing Options](#routing-options)

Bin Packing

- [The Knapsack Problem](#the-knapsack-problem)
- [Multiple Knapsacks](#multiple-knapsacks)
- [Bin Packing Problem](#bin-packing-problem)

Network Flows

- [Maximum Flows](#maximum-flows)
- [Minimum Cost Flows](#minimum-cost-flows)

Assignment

- [Assignment](#assignment)
- [Assignment as a Min Cost Problem](#assignment-as-a-min-cost-problem)
- [Assignment as a MIP Problem](#assignment-as-a-mip-problem)

Scheduling

- [Employee Scheduling](#employee-scheduling)

### The Glop Linear Solver

[Guide](https://developers.google.com/optimization/lp/glop)

Declare the solver

```ruby
solver = ORTools::Solver.new("LinearProgrammingExample", :glop)
```

Create the variables

```ruby
x = solver.num_var(0, solver.infinity, "x")
y = solver.num_var(0, solver.infinity, "y")
```

Define the constraints

```ruby
constraint0 = solver.constraint(-solver.infinity, 14)
constraint0.set_coefficient(x, 1)
constraint0.set_coefficient(y, 2)

constraint1 = solver.constraint(0, solver.infinity)
constraint1.set_coefficient(x, 3)
constraint1.set_coefficient(y, -1)

constraint2 = solver.constraint(-solver.infinity, 2)
constraint2.set_coefficient(x, 1)
constraint2.set_coefficient(y, -1)
```

Define the objective function

```ruby
objective = solver.objective
objective.set_coefficient(x, 3)
objective.set_coefficient(y, 4)
objective.set_maximization
```

Invoke the solver

```ruby
solver.solve
```

Display the solution

```ruby
opt_solution = 3 * x.solution_value + 4 * y.solution_value
puts "Number of variables = #{solver.num_variables}"
puts "Number of constraints = #{solver.num_constraints}"
puts "Solution:"
puts "x = #{x.solution_value}"
puts "y = #{y.solution_value}"
puts "Optimal objective value = #{opt_solution}"
```

### CP-SAT Solver

[Guide](https://developers.google.com/optimization/cp/cp_solver)

Declare the model

```ruby
model = ORTools::CpModel.new
```

Create the variables

```ruby
num_vals = 3
x = model.new_int_var(0, num_vals - 1, "x")
y = model.new_int_var(0, num_vals - 1, "y")
z = model.new_int_var(0, num_vals - 1, "z")
```

Create the constraint

```ruby
model.add(x != y)
```

Call the solver

```ruby
solver = ORTools::CpSolver.new
status = solver.solve(model)
```

Display the first solution

```ruby
if status == :feasible
  puts "x = #{solver.value(x)}"
  puts "y = #{solver.value(y)}"
  puts "z = #{solver.value(z)}"
end
```

### Solving an Optimization Problem

[Guide](https://developers.google.com/optimization/cp/integer_opt_cp)

Declare the model

```ruby
model = ORTools::CpModel.new
```

Create the variables

```ruby
var_upper_bound = [50, 45, 37].max
x = model.new_int_var(0, var_upper_bound, "x")
y = model.new_int_var(0, var_upper_bound, "y")
z = model.new_int_var(0, var_upper_bound, "z")
```

Define the constraints

```ruby
model.add(x*2 + y*7 + z*3 <= 50)
model.add(x*3 - y*5 + z*7 <= 45)
model.add(x*5 + y*2 - z*6 <= 37)
```

Define the objective function

```ruby
model.maximize(x*2 + y*2 + z*3)
```

Call the solver

```ruby
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

### Mixed-Integer Programming

[Guide](https://developers.google.com/optimization/mip/integer_opt)

Declare the MIP solver

```ruby
solver = ORTools::Solver.new("simple_mip_program", :cbc)
```

Define the variables

```ruby
infinity = solver.infinity
x = solver.int_var(0.0, infinity, "x")
y = solver.int_var(0.0, infinity, "y")

puts "Number of variables = #{solver.num_variables}"
```

Define the constraints

```ruby
c0 = solver.constraint(-infinity, 17.5)
c0.set_coefficient(x, 1)
c0.set_coefficient(y, 7)

c1 = solver.constraint(-infinity, 3.5)
c1.set_coefficient(x, 1);
c1.set_coefficient(y, 0);

puts "Number of constraints = #{solver.num_constraints}"
```

Define the objective

```ruby
objective = solver.objective
objective.set_coefficient(x, 1)
objective.set_coefficient(y, 10)
objective.set_maximization
```

Call the solver

```ruby
status = solver.solve
```

Display the solution

```ruby
if status == :optimal
  puts "Solution:"
  puts "Objective value = #{solver.objective.value}"
  puts "x = #{x.solution_value}"
  puts "y = #{y.solution_value}"
else
  puts "The problem does not have an optimal solution."
end
```

### Traveling Salesperson Problem (TSP)

[Guide](https://developers.google.com/optimization/routing/tsp.html)

Create the data

```ruby
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
```

Create the distance callback

```ruby
manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
```

Run the solver

```ruby
assignment = routing.solve(first_solution_strategy: :path_cheaper_arc)
```

Print the solution

```ruby
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

Create the data

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
data[:num_vehicles] = 4
data[:depot] = 0
```

Define the distance callback

```ruby
manager = ORTools::RoutingIndexManager.new(data[:distance_matrix].length, data[:num_vehicles], data[:depot])
routing = ORTools::RoutingModel.new(manager)

distance_callback = lambda do |from_index, to_index|
  from_node = manager.index_to_node(from_index)
  to_node = manager.index_to_node(to_index)
  data[:distance_matrix][from_node][to_node]
end

transit_callback_index = routing.register_transit_callback(distance_callback)
routing.set_arc_cost_evaluator_of_all_vehicles(transit_callback_index)
```

Add a distance dimension

```ruby
dimension_name = "Distance"
routing.add_dimension(transit_callback_index, 0, 3000, true, dimension_name)
distance_dimension = routing.mutable_dimension(dimension_name)
distance_dimension.global_span_cost_coefficient = 100
```

Run the solver

```ruby
solution = routing.solve(first_solution_strategy: :path_cheapest_arc)
```

Print the solution

```ruby
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

Create the data

```ruby
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
```

Declare the solver

```ruby
solver = ORTools::KnapsackSolver.new(:branch_and_bound, "KnapsackExample")
```

Call the solver

```ruby
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

Create the data

```ruby
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
```

Declare the solver

```ruby
solver = ORTools::Solver.new("simple_mip_program", :cbc)
```

Create the variables

```ruby
x = {}
data[:items].each do |i|
  data[:bins].each do |j|
    x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
  end
end
```

Define the constraints

```ruby
data[:items].each do |i|
  sum = ORTools::LinearExpr.new
  data[:bins].each do |j|
    sum += x[[i, j]]
  end
  solver.add(sum <= 1.0)
end

data[:bins].each do |j|
  weight = ORTools::LinearExpr.new
  data[:items].each do |i|
    weight += x[[i, j]] * data[:weights][i]
  end
  solver.add(weight <= data[:bin_capacities][j])
end
```

Define the objective

```ruby
objective = solver.objective

data[:items].each do |i|
  data[:bins].each do |j|
    objective.set_coefficient(x[[i, j]], data[:values][i])
  end
end
objective.set_maximization
```

Call the solver and print the solution

```ruby
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

Create the data

```ruby
data = {}
weights = [48, 30, 19, 36, 36, 27, 42, 42, 36, 24, 30]
data[:weights] = weights
data[:items] = (0...weights.length).to_a
data[:bins] = data[:items]
data[:bin_capacity] = 100
```

Declare the solver

```ruby
solver = ORTools::Solver.new("simple_mip_program", :cbc)
```

Create the variables

```ruby
x = {}
data[:items].each do |i|
  data[:bins].each do |j|
    x[[i, j]] = solver.int_var(0, 1, "x_%i_%i" % [i, j])
  end
end

y = {}
data[:bins].each do |j|
  y[j] = solver.int_var(0, 1, "y[%i]" % j)
end
```

Define the constraints

```ruby
data[:items].each do |i|
  solver.add(solver.sum(data[:bins].map { |j| x[[i, j]] }) == 1)
end

data[:bins].each do |j|
  sum = solver.sum(data[:items].map { |i| x[[i, j]] * data[:weights][i] })
  solver.add(sum <= y[j] * data[:bin_capacity])
end
```

Define the objective

```ruby
solver.minimize(solver.sum(data[:bins].map { |j| y[j] }))
```

Call the solver and print the solution

```ruby
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

Define the data

```ruby
start_nodes = [0, 0, 0, 1, 1, 2, 2, 3, 3]
end_nodes = [1, 2, 3, 2, 4, 3, 4, 2, 4]
capacities = [20, 30, 10, 40, 30, 10, 20, 5, 20]
```

Declare the solver and add the arcs

```ruby
max_flow = ORTools::SimpleMaxFlow.new

start_nodes.length.times do |i|
  max_flow.add_arc_with_capacity(start_nodes[i], end_nodes[i], capacities[i])
end
```

Invoke the solver and display the results

```ruby
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

Define the data

```ruby
start_nodes = [ 0, 0,  1, 1,  1,  2, 2,  3, 4]
end_nodes   = [ 1, 2,  2, 3,  4,  3, 4,  4, 2]
capacities  = [15, 8, 20, 4, 10, 15, 4, 20, 5]
unit_costs  = [ 4, 4,  2, 2,  6,  1, 3,  2, 3]
supplies = [20, 0, 0, -5, -15]
```

Declare the solver and add the arcs

```ruby
min_cost_flow = ORTools::SimpleMinCostFlow.new

start_nodes.length.times do |i|
  min_cost_flow.add_arc_with_capacity_and_unit_cost(
    start_nodes[i], end_nodes[i], capacities[i], unit_costs[i]
  )
end

supplies.length.times do |i|
  min_cost_flow.set_node_supply(i, supplies[i])
end
```

Invoke the solver and display the results

```ruby
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

## Assignment

[Guide](https://developers.google.com/optimization/assignment/simple_assignment)

Create the data

```ruby
cost = [[ 90,  76, 75,  70],
        [ 35,  85, 55,  65],
        [125,  95, 90, 105],
        [ 45, 110, 95, 115]]

rows = cost.length
cols = cost[0].length
```

Create the solver

```ruby
assignment = ORTools::LinearSumAssignment.new
```

Add the costs to the solver

```ruby
rows.times do |worker|
  cols.times do |task|
    if cost[worker][task]
      assignment.add_arc_with_cost(worker, task, cost[worker][task])
    end
  end
end
```

Invoke the solver

```ruby
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

## Assignment as a Min Cost Problem

[Guide](https://developers.google.com/optimization/assignment/assignment_min_cost_flow)

Create the solver

```ruby
min_cost_flow = ORTools::SimpleMinCostFlow.new
```

Create the data

```ruby
start_nodes = [0, 0, 0, 0] + [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4] + [5, 6, 7, 8]
end_nodes = [1, 2, 3, 4] + [5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8] + [9, 9, 9, 9]
capacities = [1, 1, 1, 1] + [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] + [1, 1, 1, 1]
costs = [0, 0, 0, 0] + [90, 76, 75, 70, 35, 85, 55, 65, 125, 95, 90, 105, 45, 110, 95, 115] + [0, 0, 0, 0]
supplies = [4, 0, 0, 0, 0, 0, 0, 0, 0, -4]
source = 0
sink = 9
tasks = 4
```

Create the graph and constraints

```ruby
start_nodes.length.times do |i|
  min_cost_flow.add_arc_with_capacity_and_unit_cost(
    start_nodes[i], end_nodes[i], capacities[i], costs[i]
  )
end

supplies.length.times do |i|
  min_cost_flow.set_node_supply(i, supplies[i])
end
```

Invoke the solver

```ruby
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

## Assignment as a MIP Problem

[Guide](https://developers.google.com/optimization/assignment/assignment_mip)

Create the solver

```ruby
solver = ORTools::Solver.new("SolveAssignmentProblemMIP", :cbc)
```

Create the data

```ruby
cost = [[90, 76, 75, 70],
        [35, 85, 55, 65],
        [125, 95, 90, 105],
        [45, 110, 95, 115],
        [60, 105, 80, 75],
        [45, 65, 110, 95]]

team1 = [0, 2, 4]
team2 = [1, 3, 5]
team_max = 2
```

Create the variables

```ruby
num_workers = cost.length
num_tasks = cost[1].length
x = {}

num_workers.times do |i|
  num_tasks.times do |j|
    x[[i, j]] = solver.bool_var("x[#{i},#{j}]")
  end
end
```

Create the objective function

```ruby
solver.minimize(solver.sum(
  num_workers.times.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] * cost[i][j] } }
))
```

Create the constraints

```ruby
num_workers.times do |i|
  solver.add(solver.sum(num_tasks.times.map { |j| x[[i, j]] }) <= 1)
end

num_tasks.times do |j|
  solver.add(solver.sum(num_workers.times.map { |i| x[[i, j]] }) == 1)
end

solver.add(solver.sum(team1.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)
solver.add(solver.sum(team2.flat_map { |i| num_tasks.times.map { |j| x[[i, j]] } }) <= team_max)
```

Invoke the solver

```ruby
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

## Employee Scheduling

[Guide](https://developers.google.com/optimization/scheduling/employee_scheduling)

Define the data

```ruby
num_nurses = 4
num_shifts = 3
num_days = 3
all_nurses = num_nurses.times.to_a
all_shifts = num_shifts.times.to_a
all_days = num_days.times.to_a
```

Create the variables

```ruby
model = ORTools::CpModel.new

shifts = {}
all_nurses.each do |n|
  all_days.each do |d|
    all_shifts.each do |s|
      shifts[[n, d, s]] = model.new_bool_var("shift_n%id%is%i" % [n, d, s])
    end
  end
end
```

Assign nurses to shifts

```ruby
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
```

Assign shifts evenly

```ruby
min_shifts_per_nurse = (num_shifts * num_days) / num_nurses
max_shifts_per_nurse = min_shifts_per_nurse + 1
all_nurses.each do |n|
  num_shifts_worked = model.sum(all_days.flat_map { |d| all_shifts.map { |s| shifts[[n, d, s]] } })
  model.add(num_shifts_worked >= min_shifts_per_nurse)
  model.add(num_shifts_worked <= max_shifts_per_nurse)
end
```

Create a printer

```ruby
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
```

Call the solver and display the results

```ruby
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
bundle exec rake compile -- --with-or-tools-dir=/path/to/or-tools
bundle exec rake test
```

Resources

- [OR-Tools Reference](https://developers.google.com/optimization/reference)
