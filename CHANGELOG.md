## 0.11.1 (unreleased)

- Added binary installation for Arch Linux

## 0.11.0 (2023-11-16)

- Updated OR-Tools to 9.8
- Dropped support for Ubuntu 18.04, Debian 10, and CentOS 8
- Dropped support for Ruby < 3

## 0.10.1 (2023-03-20)

- Added `domain` method to `SatIntVar`
- Added `add_linear_constraint` and `add_linear_expression_in_domain` methods to `CpModel`

## 0.10.0 (2023-03-15)

- Updated OR-Tools to 9.6

## 0.9.1 (2023-03-11)

- Added `solution_info` to `CpSolver`

## 0.9.0 (2022-12-02)

- Updated OR-Tools to 9.5
- Added `solve_from_assignment_with_parameters` to `RoutingModel`
- Improved `inspect` and `to_s` for expressions

## 0.8.2 (2022-11-05)

- Added support for bool vars to `add_hint`
- Added support for empty sums to `CpModel`

## 0.8.1 (2022-08-22)

- Added binary installation for Ubuntu 22.04

## 0.8.0 (2022-08-21)

- Updated OR-Tools to 9.4
- Added binary installation for Mac ARM
- Restored support for Debian 10
- Dropped support for Ruby < 2.7

## 0.7.3 (2022-07-23)

- Added more methods to `RoutingModel` and `RoutingDimension`

## 0.7.2 (2022-05-28)

- Fixed library not loaded error on Mac

## 0.7.1 (2022-05-27)

- Added support for time limit for `Solver`
- Added `enable_output` and `suppress_output` to `Solver`
- Improved `new` method for `Solver`
- Fixed error with offset with `Solver`
- Fixed segfault with `CpSolver`

## 0.7.0 (2022-03-23)

- Updated OR-Tools to 9.3
- Removed `add_lin_min_equality` (use `add_min_equality` instead)
- Removed `add_lin_max_equality` (use `add_max_equality` instead)
- Dropped support for Debian 10

## 0.6.3 (2022-03-13)

- Reduced gem size

## 0.6.2 (2022-02-09)

- Fixed segfaults with `Solver`

## 0.6.1 (2022-01-22)

- Added installation instructions for Mac ARM
- Removed dependency on `lsb_release` for binary installation on Linux

## 0.6.0 (2021-12-16)

- Updated OR-Tools to 9.2
- Renamed `add_product_equality` to `add_multiplication_equality`
- Removed `scale_objective_by`

## 0.5.4 (2021-10-01)

- Updated OR-Tools to 9.1
- Added binary installation for Debian 11
- Deprecated `solve_with_solution_callback` and `search_for_all_solutions`

## 0.5.3 (2021-08-02)

- Added more methods to `IntVar`, `IntervalVar`, and `Constraint`
- Added `RoutingModelParameters`

## 0.5.2 (2021-07-07)

- Added `export_model_as_lp_format` and `export_model_as_mps_format` to `Solver`

## 0.5.1 (2021-05-23)

- Updated to Rice 4

## 0.5.0 (2021-04-30)

- Updated OR-Tools to 9.0
- Added binary installation for CentOS 7
- Added `sufficient_assumptions_for_infeasibility` to `CpSolver`

## 0.4.3 (2021-03-26)

- Added `add_assumption`, `add_assumptions`, and `clear_assumptions` to `CpModel`
- Added `add_hint` and `clear_hints` to `CpModel`
- Added `only_enforce_if` to `SatConstraint`
- Fixed installation for Debian

## 0.4.2 (2021-03-03)

- Updated OR-Tools to 8.2

## 0.4.1 (2021-02-23)

- Added solution printers
- Improved `inspect` and `to_s` for `CpModel`
- Improved constraint construction

## 0.4.0 (2021-01-14)

- Updated OR-Tools to 8.1

## 0.3.4 (2021-01-14)

- Added support for time limit for `CpSolver`
- Added `add_dimension_with_vehicle_transits` and `status` methods to `RoutingModel`

## 0.3.3 (2020-10-12)

- Added support for start and end points for routing

## 0.3.2 (2020-08-04)

- Updated OR-Tools to 7.8
- Added binary installation for Ubuntu 20.04

## 0.3.1 (2020-07-21)

- Reduced gem size

## 0.3.0 (2020-07-21)

- Updated OR-Tools to 7.7
- Added `BasicScheduler` class
- Added `Seating` class
- Added `TSP` class
- Added `Sudoku` class

## 0.2.0 (2020-05-22)

- No longer need to download the OR-Tools C++ library separately on Mac, Ubuntu 18.04, Ubuntu 16.04, Debian 10, and CentOS 8

## 0.1.5 (2020-04-23)

- Added support for OR-Tools 7.6

## 0.1.4 (2020-04-19)

- Added support for the Job Shop Problem

## 0.1.3 (2020-03-24)

- Added support for more routing problems
- Added `add_all_different` to `CpModel`

## 0.1.2 (2020-02-18)

- Added support for scheduling
- Added `lib_version` method

## 0.1.1 (2020-02-16)

- Added `RoutingModel`
- Added `LinearSumAssignment`
- Added `Solver`

## 0.1.0 (2020-02-12)

- First release
