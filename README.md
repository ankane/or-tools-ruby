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

Constraint Optimization

- [CP-SAT Solver](#cp-sat-solver)

Bin Packing

- [The Knapsack Problem](#the-knapsack-problem)

Network Flows

- [Maximum Flows](#maximum-flows)
- [Minimum Cost Flows](#minimum-cost-flows)

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
model.add_not_equal(x, y)
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
