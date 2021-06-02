## 0.5.2 (unreleased)

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
