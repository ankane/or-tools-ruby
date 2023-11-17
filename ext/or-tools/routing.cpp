#include <ortools/constraint_solver/routing.h>
#include <ortools/constraint_solver/routing_parameters.h>

#include "ext.h"

using operations_research::Assignment;
using operations_research::ConstraintSolverParameters;
using operations_research::DefaultRoutingSearchParameters;
using operations_research::FirstSolutionStrategy;
using operations_research::LocalSearchMetaheuristic;
using operations_research::RoutingDimension;
using operations_research::RoutingDisjunctionIndex;
using operations_research::RoutingIndexManager;
using operations_research::RoutingModel;
using operations_research::RoutingModelParameters;
using operations_research::RoutingNodeIndex;
using operations_research::RoutingSearchParameters;

using Rice::Array;
using Rice::Class;
using Rice::Module;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

namespace Rice::detail
{
  template<>
  struct Type<RoutingNodeIndex>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class From_Ruby<RoutingNodeIndex>
  {
  public:
    RoutingNodeIndex convert(VALUE x)
    {
      const RoutingNodeIndex index{From_Ruby<int>().convert(x)};
      return index;
    }
  };

  template<>
  class To_Ruby<RoutingNodeIndex>
  {
  public:
    VALUE convert(RoutingNodeIndex const & x)
    {
      return To_Ruby<int>().convert(x.value());
    }
  };
}

namespace Rice::detail
{
  template<class T, class U>
  class To_Ruby<std::pair<T, U>>
  {
  public:
    VALUE convert(std::pair<T, U> const & x)
    {
      return rb_ary_new3(2, To_Ruby<T>().convert(x.first), To_Ruby<U>().convert(x.second));
    }
  };
}

void init_routing(Rice::Module& m) {
  auto rb_cRoutingSearchParameters = Rice::define_class_under<RoutingSearchParameters>(m, "RoutingSearchParameters");
  auto rb_cIntVar = Rice::define_class_under<operations_research::IntVar>(m, "IntVar");

  m.define_singleton_function("default_routing_search_parameters", &DefaultRoutingSearchParameters);

  rb_cRoutingSearchParameters
    .define_method(
      "first_solution_strategy=",
      [](RoutingSearchParameters& self, Symbol value) {
        auto s = Symbol(value).str();

        FirstSolutionStrategy::Value v;
        if (s == "path_cheapest_arc") {
          v = FirstSolutionStrategy::PATH_CHEAPEST_ARC;
        } else if (s == "path_most_constrained_arc") {
          v = FirstSolutionStrategy::PATH_MOST_CONSTRAINED_ARC;
        } else if (s == "evaluator_strategy") {
          v = FirstSolutionStrategy::EVALUATOR_STRATEGY;
        } else if (s == "savings") {
          v = FirstSolutionStrategy::SAVINGS;
        } else if (s == "sweep") {
          v = FirstSolutionStrategy::SWEEP;
        } else if (s == "christofides") {
          v = FirstSolutionStrategy::CHRISTOFIDES;
        } else if (s == "all_unperformed") {
          v = FirstSolutionStrategy::ALL_UNPERFORMED;
        } else if (s == "best_insertion") {
          v = FirstSolutionStrategy::BEST_INSERTION;
        } else if (s == "parallel_cheapest_insertion") {
          v = FirstSolutionStrategy::PARALLEL_CHEAPEST_INSERTION;
        } else if (s == "sequential_cheapest_insertion") {
          v = FirstSolutionStrategy::SEQUENTIAL_CHEAPEST_INSERTION;
        } else if (s == "local_cheapest_insertion") {
          v = FirstSolutionStrategy::LOCAL_CHEAPEST_INSERTION;
        } else if (s == "global_cheapest_arc") {
          v = FirstSolutionStrategy::GLOBAL_CHEAPEST_ARC;
        } else if (s == "local_cheapest_arc") {
          v = FirstSolutionStrategy::LOCAL_CHEAPEST_ARC;
        } else if (s == "first_unbound_min_value") {
          v = FirstSolutionStrategy::FIRST_UNBOUND_MIN_VALUE;
        } else {
          throw std::runtime_error("Unknown first solution strategy: " + s);
        }

        return self.set_first_solution_strategy(v);
      })
    .define_method(
      "local_search_metaheuristic=",
      [](RoutingSearchParameters& self, Symbol value) {
        auto s = Symbol(value).str();

        LocalSearchMetaheuristic::Value v;
        if (s == "guided_local_search") {
          v = LocalSearchMetaheuristic::GUIDED_LOCAL_SEARCH;
        } else if (s == "tabu_search") {
          v = LocalSearchMetaheuristic::TABU_SEARCH;
        } else if (s == "generic_tabu_search") {
          v = LocalSearchMetaheuristic::GENERIC_TABU_SEARCH;
        } else if (s == "simulated_annealing") {
          v = LocalSearchMetaheuristic::SIMULATED_ANNEALING;
        } else {
          throw std::runtime_error("Unknown local search metaheuristic: " + s);
        }

        return self.set_local_search_metaheuristic(v);
      })
    .define_method(
      "log_search=",
      [](RoutingSearchParameters& self, bool value) {
        self.set_log_search(value);
      })
    .define_method(
      "solution_limit=",
      [](RoutingSearchParameters& self, int64_t value) {
        self.set_solution_limit(value);
      })
    .define_method(
      "time_limit=",
      [](RoutingSearchParameters& self, int64_t value) {
        self.mutable_time_limit()->set_seconds(value);
      })
    .define_method(
      "lns_time_limit=",
      [](RoutingSearchParameters& self, int64_t value) {
        self.mutable_lns_time_limit()->set_seconds(value);
      });

  Rice::define_class_under<RoutingIndexManager>(m, "RoutingIndexManager")
    .define_singleton_function(
      "_new_depot",
      [](int num_nodes, int num_vehicles, RoutingNodeIndex depot) {
        return RoutingIndexManager(num_nodes, num_vehicles, depot);
      })
    .define_singleton_function(
      "_new_starts_ends",
      [](int num_nodes, int num_vehicles, std::vector<RoutingNodeIndex> starts, std::vector<RoutingNodeIndex> ends) {
        return RoutingIndexManager(num_nodes, num_vehicles, starts, ends);
      })
    .define_method("index_to_node", &RoutingIndexManager::IndexToNode)
    .define_method("node_to_index", &RoutingIndexManager::NodeToIndex);

  Rice::define_class_under<Assignment>(m, "Assignment")
    .define_method("objective_value", &Assignment::ObjectiveValue)
    .define_method("value", &Assignment::Value)
    .define_method("min", &Assignment::Min)
    .define_method("max", &Assignment::Max);

  // not to be confused with operations_research::sat::IntVar
  rb_cIntVar
    .define_method("var?", &operations_research::IntVar::IsVar)
    .define_method("value", &operations_research::IntVar::Value)
    .define_method("remove_value", &operations_research::IntVar::RemoveValue)
    .define_method("remove_interval", &operations_research::IntVar::RemoveInterval)
    .define_method("remove_values", &operations_research::IntVar::RemoveValues)
    .define_method("set_values", &operations_research::IntVar::SetValues)
    .define_method("size", &operations_research::IntVar::Size)
    .define_method("contains", &operations_research::IntVar::Contains)
    .define_method("old_min", &operations_research::IntVar::OldMin)
    .define_method("old_max", &operations_research::IntVar::OldMax)
    .define_method(
      "set_range",
      [](operations_research::IntVar& self, int64_t new_min, int64_t new_max) {
        self.SetRange(new_min, new_max);
      });

  Rice::define_class_under<operations_research::IntervalVar>(m, "IntervalVar")
    .define_method("start_min", &operations_research::IntervalVar::StartMin)
    .define_method("start_max", &operations_research::IntervalVar::StartMax)
    .define_method("set_start_min", &operations_research::IntervalVar::SetStartMin)
    .define_method("set_start_max", &operations_research::IntervalVar::SetStartMax)
    .define_method("set_start_range", &operations_research::IntervalVar::SetStartRange)
    .define_method("old_start_min", &operations_research::IntervalVar::OldStartMin)
    .define_method("old_start_max", &operations_research::IntervalVar::OldStartMax)
    .define_method("end_min", &operations_research::IntervalVar::EndMin)
    .define_method("end_max", &operations_research::IntervalVar::EndMax)
    .define_method("set_end_min", &operations_research::IntervalVar::SetEndMin)
    .define_method("set_end_max", &operations_research::IntervalVar::SetEndMax)
    .define_method("set_end_range", &operations_research::IntervalVar::SetEndRange)
    .define_method("old_end_min", &operations_research::IntervalVar::OldEndMin)
    .define_method("old_end_max", &operations_research::IntervalVar::OldEndMax);

  Rice::define_class_under<RoutingDimension>(m, "RoutingDimension")
    .define_method("transit_value", &RoutingDimension::GetTransitValue)
    // TODO GetTransitValueFromClass
    .define_method("cumul_var", &RoutingDimension::CumulVar)
    .define_method("transit_var", &RoutingDimension::TransitVar)
    .define_method("fixed_transit_var", &RoutingDimension::FixedTransitVar)
    .define_method("slack_var", &RoutingDimension::SlackVar)
    .define_method("set_span_upper_bound_for_vehicle", &RoutingDimension::SetSpanUpperBoundForVehicle)
    .define_method("set_span_cost_coefficient_for_vehicle", &RoutingDimension::SetSpanCostCoefficientForVehicle)
    .define_method("set_span_cost_coefficient_for_all_vehicles", &RoutingDimension::SetSpanCostCoefficientForAllVehicles)
    .define_method("set_global_span_cost_coefficient", &RoutingDimension::SetGlobalSpanCostCoefficient)
    // alias
    .define_method("global_span_cost_coefficient=", &RoutingDimension::SetGlobalSpanCostCoefficient)
    .define_method("set_cumul_var_soft_upper_bound", &RoutingDimension::SetCumulVarSoftUpperBound)
    .define_method("cumul_var_soft_upper_bound?", &RoutingDimension::HasCumulVarSoftUpperBound)
    .define_method("cumul_var_soft_upper_bound", &RoutingDimension::GetCumulVarSoftUpperBound)
    .define_method("cumul_var_soft_upper_bound_coefficient", &RoutingDimension::GetCumulVarSoftUpperBoundCoefficient)
    .define_method("set_cumul_var_soft_lower_bound", &RoutingDimension::SetCumulVarSoftLowerBound)
    .define_method("cumul_var_soft_lower_bound?", &RoutingDimension::HasCumulVarSoftLowerBound)
    .define_method("cumul_var_soft_lower_bound", &RoutingDimension::GetCumulVarSoftLowerBound)
    .define_method("cumul_var_soft_lower_bound_coefficient", &RoutingDimension::GetCumulVarSoftLowerBoundCoefficient);

  Rice::define_class_under<RoutingDisjunctionIndex>(m, "RoutingDisjunctionIndex");

  Rice::define_class_under<operations_research::Constraint>(m, "Constraint")
    .define_method("post", &operations_research::Constraint::Post)
    .define_method("debug_string", &operations_research::Constraint::DebugString);

  Rice::define_class_under<operations_research::Solver>(m, "Solver2")
    .define_method(
      "add",
      [](operations_research::Solver& self, Object o) {
        operations_research::Constraint* constraint;
        if (o.respond_to("left")) {
          operations_research::IntExpr* left(Rice::detail::From_Ruby<operations_research::IntVar*>().convert(o.call("left")));
          operations_research::IntExpr* right(Rice::detail::From_Ruby<operations_research::IntVar*>().convert(o.call("right")));
          auto op = o.call("operator").to_s().str();
          if (op == "==") {
            constraint = self.MakeEquality(left, right);
          } else if (op == "<=") {
            constraint = self.MakeLessOrEqual(left, right);
          } else {
            throw std::runtime_error("Unknown operator");
          }
        } else {
          constraint = Rice::detail::From_Ruby<operations_research::Constraint*>().convert(o);
        }
        self.AddConstraint(constraint);
      })
    .define_method(
      "fixed_duration_interval_var",
      [](operations_research::Solver& self, operations_research::IntVar* const start_variable, int64_t duration, const std::string& name) {
        return self.MakeFixedDurationIntervalVar(start_variable, duration, name);
      })
    .define_method(
      "cumulative",
      [](operations_research::Solver& self, std::vector<operations_research::IntervalVar*> intervals, std::vector<int64_t> demands, int64_t capacity, const std::string& name) {
        return self.MakeCumulative(intervals, demands, capacity, name);
      });

  Rice::define_class_under<ConstraintSolverParameters>(m, "ConstraintSolverParameters")
    .define_method(
      "trace_propagation=",
      [](ConstraintSolverParameters& self, bool value) {
        self.set_trace_propagation(value);
      })
    .define_method(
      "trace_search=",
      [](ConstraintSolverParameters& self, bool value) {
        self.set_trace_search(value);
      });

  Rice::define_class_under<RoutingModelParameters>(m, "RoutingModelParameters")
    .define_method(
      "solver_parameters",
      [](RoutingModelParameters& self) {
        return self.mutable_solver_parameters();
      });

  m.define_singleton_function(
    "default_routing_model_parameters",
    []() {
      return operations_research::DefaultRoutingModelParameters();
    });

  Rice::define_class_under<RoutingModel>(m, "RoutingModel")
    .define_constructor(Rice::Constructor<RoutingModel, RoutingIndexManager, RoutingModelParameters>(), Rice::Arg("index_manager"), Rice::Arg("parameters") = operations_research::DefaultRoutingModelParameters())
    .define_method("register_unary_transit_vector", &RoutingModel::RegisterUnaryTransitVector)
    .define_method(
      "register_unary_transit_callback",
      [](RoutingModel& self, Object callback) {
        return self.RegisterUnaryTransitCallback(
          [callback](int64_t from_index) -> int64_t {
            return Rice::detail::From_Ruby<int64_t>().convert(callback.call("call", from_index));
          }
        );
      })
    .define_method("register_transit_matrix", &RoutingModel::RegisterTransitMatrix)
    .define_method(
      "register_transit_callback",
      [](RoutingModel& self, Object callback) {
        return self.RegisterTransitCallback(
          [callback](int64_t from_index, int64_t to_index) -> int64_t {
            return Rice::detail::From_Ruby<int64_t>().convert(callback.call("call", from_index, to_index));
          }
        );
      })
    .define_method("add_dimension", &RoutingModel::AddDimension)
    .define_method("add_dimension_with_vehicle_transits", &RoutingModel::AddDimensionWithVehicleTransits)
    .define_method("add_dimension_with_vehicle_capacity", &RoutingModel::AddDimensionWithVehicleCapacity)
    .define_method("add_dimension_with_vehicle_transit_and_capacity", &RoutingModel::AddDimensionWithVehicleTransitAndCapacity)
    .define_method("add_constant_dimension_with_slack", &RoutingModel::AddConstantDimensionWithSlack)
    .define_method("add_constant_dimension", &RoutingModel::AddConstantDimension)
    .define_method("add_vector_dimension", &RoutingModel::AddVectorDimension)
    .define_method("add_matrix_dimension", &RoutingModel::AddMatrixDimension)
    // TODO AddDimensionDependentDimensionWithVehicleCapacity
    // .define_method("make_path_spans_and_total_slacks", &RoutingModel::MakePathSpansAndTotalSlacks)
    .define_method("all_dimension_names", &RoutingModel::GetAllDimensionNames)
    // .define_method("dimensions", &RoutingModel::GetDimensions)
    // .define_method("dimensions_with_soft_or_span_costs", &RoutingModel::GetDimensionsWithSoftOrSpanCosts)
    .define_method("dimension?", &RoutingModel::HasDimension)
    // .define_method("dimension_or_die", &RoutingModel::GetDimensionOrDie)
    .define_method("mutable_dimension", &RoutingModel::GetMutableDimension)
    .define_method("set_primary_constrained_dimension", &RoutingModel::SetPrimaryConstrainedDimension)
    .define_method("primary_constrained_dimension", &RoutingModel::GetPrimaryConstrainedDimension)
    .define_method("add_resource_group", &RoutingModel::AddResourceGroup)
    .define_method("dimension_resource_group_indices", &RoutingModel::GetDimensionResourceGroupIndices)
    .define_method("dimension_resource_group_index", &RoutingModel::GetDimensionResourceGroupIndex)
    .define_method("add_disjunction", &RoutingModel::AddDisjunction, Rice::Arg("indices"), Rice::Arg("penalty"), Rice::Arg("max_cardinality") = (int64_t)1)
    .define_method("disjunction_indices", &RoutingModel::GetDisjunctionIndices)
    .define_method("disjunction_penalty", &RoutingModel::GetDisjunctionPenalty)
    .define_method("disjunction_max_cardinality", &RoutingModel::GetDisjunctionMaxCardinality)
    .define_method("number_of_disjunctions", &RoutingModel::GetNumberOfDisjunctions)
    .define_method("mandatory_disjunctions?", &RoutingModel::HasMandatoryDisjunctions)
    .define_method("max_cardinality_constrained_disjunctions?", &RoutingModel::HasMaxCardinalityConstrainedDisjunctions)
    .define_method("perfect_binary_disjunctions", &RoutingModel::GetPerfectBinaryDisjunctions)
    .define_method("ignore_disjunctions_already_forced_to_zero", &RoutingModel::IgnoreDisjunctionsAlreadyForcedToZero)
    .define_method("add_soft_same_vehicle_constraint", &RoutingModel::AddSoftSameVehicleConstraint)
    .define_method("set_allowed_vehicles_for_index", &RoutingModel::SetAllowedVehiclesForIndex)
    .define_method("vehicle_allowed_for_index?", &RoutingModel::IsVehicleAllowedForIndex)
    .define_method("add_pickup_and_delivery", &RoutingModel::AddPickupAndDelivery)
    .define_method("add_pickup_and_delivery_sets", &RoutingModel::AddPickupAndDeliverySets)
    .define_method(
      "pickup_positions",
      [](RoutingModel& self, int64_t node_index) {
        std::vector<std::pair<int, int>> positions;
        for (const auto& v : self.GetPickupPositions(node_index)) {
          positions.emplace_back(v.pd_pair_index, v.alternative_index);
        }
        return positions;
      })
    .define_method(
      "delivery_positions",
      [](RoutingModel& self, int64_t node_index) {
        std::vector<std::pair<int, int>> positions;
        for (const auto& v : self.GetDeliveryPositions(node_index)) {
          positions.emplace_back(v.pd_pair_index, v.alternative_index);
        }
        return positions;
      })
    // TODO SetPickupAndDeliveryPolicyOfAllVehicles
    // TODO SetPickupAndDeliveryPolicyOfVehicle
    // TODO GetPickupAndDeliveryPolicyOfVehicle
    .define_method("num_of_singleton_nodes", &RoutingModel::GetNumOfSingletonNodes)
    .define_method("unperformed_penalty", &RoutingModel::UnperformedPenalty)
    .define_method("unperformed_penalty_or_value", &RoutingModel::UnperformedPenaltyOrValue)
    .define_method("depot", &RoutingModel::GetDepot)
    .define_method("set_maximum_number_of_active_vehicles", &RoutingModel::SetMaximumNumberOfActiveVehicles)
    .define_method("maximum_number_of_active_vehicles", &RoutingModel::GetMaximumNumberOfActiveVehicles)
    .define_method("set_arc_cost_evaluator_of_all_vehicles", &RoutingModel::SetArcCostEvaluatorOfAllVehicles)
    .define_method("set_arc_cost_evaluator_of_vehicle", &RoutingModel::SetArcCostEvaluatorOfVehicle)
    .define_method("set_fixed_cost_of_all_vehicles", &RoutingModel::SetFixedCostOfAllVehicles)
    .define_method("set_fixed_cost_of_vehicle", &RoutingModel::SetFixedCostOfVehicle)
    .define_method("fixed_cost_of_vehicle", &RoutingModel::GetFixedCostOfVehicle)
    .define_method("set_amortized_cost_factors_of_all_vehicles", &RoutingModel::SetAmortizedCostFactorsOfAllVehicles)
    .define_method("set_amortized_cost_factors_of_vehicle", &RoutingModel::SetAmortizedCostFactorsOfVehicle)
    .define_method("amortized_linear_cost_factor_of_vehicles", &RoutingModel::GetAmortizedLinearCostFactorOfVehicles)
    .define_method("amortized_quadratic_cost_factor_of_vehicles", &RoutingModel::GetAmortizedQuadraticCostFactorOfVehicles)
    .define_method("set_vehicle_used_when_empty", &RoutingModel::SetVehicleUsedWhenEmpty)
    .define_method("vehicle_used_when_empty?", &RoutingModel::IsVehicleUsedWhenEmpty)
    .define_method("add_variable_minimized_by_finalizer", &RoutingModel::AddVariableMinimizedByFinalizer)
    .define_method("add_variable_maximized_by_finalizer", &RoutingModel::AddVariableMaximizedByFinalizer)
    .define_method("add_weighted_variable_minimized_by_finalizer", &RoutingModel::AddWeightedVariableMinimizedByFinalizer)
    .define_method("add_weighted_variable_maximized_by_finalizer", &RoutingModel::AddWeightedVariableMaximizedByFinalizer)
    .define_method("add_variable_target_to_finalizer", &RoutingModel::AddVariableTargetToFinalizer)
    .define_method("add_weighted_variable_target_to_finalizer", &RoutingModel::AddWeightedVariableTargetToFinalizer)
    .define_method("close_model", &RoutingModel::CloseModel)
    // solve defined in Ruby
    .define_method(
      "solve_with_parameters",
      [](RoutingModel& self, const RoutingSearchParameters& search_parameters) {
        return self.SolveWithParameters(search_parameters);
      })
    .define_method(
      "solve_from_assignment_with_parameters",
      [](RoutingModel& self, const Assignment* assignment, const RoutingSearchParameters& search_parameters) {
        return self.SolveFromAssignmentWithParameters(assignment, search_parameters);
      })
    .define_method("compute_lower_bound", &RoutingModel::ComputeLowerBound)
    .define_method("status",
      [](RoutingModel& self) {
        auto status = self.status();

        if (status == RoutingModel::ROUTING_NOT_SOLVED) {
          return Symbol("not_solved");
        } else if (status == RoutingModel::ROUTING_SUCCESS) {
          return Symbol("success");
        } else if (status == RoutingModel::ROUTING_FAIL) {
          return Symbol("fail");
        } else if (status == RoutingModel::ROUTING_FAIL_TIMEOUT) {
          return Symbol("fail_timeout");
        } else if (status == RoutingModel::ROUTING_INVALID) {
          return Symbol("invalid");
        } else {
          throw std::runtime_error("Unknown solver status");
        }
      })
    .define_method("apply_locks", &RoutingModel::ApplyLocks)
    .define_method("apply_locks_to_all_vehicles", &RoutingModel::ApplyLocksToAllVehicles)
    .define_method("pre_assignment", &RoutingModel::PreAssignment)
    .define_method("mutable_pre_assignment", &RoutingModel::MutablePreAssignment)
    .define_method("write_assignment", &RoutingModel::WriteAssignment)
    .define_method("read_assignment", &RoutingModel::ReadAssignment)
    .define_method("restore_assignment", &RoutingModel::RestoreAssignment)
    .define_method("read_assignment_from_routes", &RoutingModel::ReadAssignmentFromRoutes)
    .define_method("routes_to_assignment", &RoutingModel::RoutesToAssignment)
    .define_method("assignment_to_routes", &RoutingModel::AssignmentToRoutes)
    .define_method("compact_assignment", &RoutingModel::CompactAssignment)
    .define_method("compact_and_check_assignment", &RoutingModel::CompactAndCheckAssignment)
    .define_method("add_to_assignment", &RoutingModel::AddToAssignment)
    .define_method("add_interval_to_assignment", &RoutingModel::AddIntervalToAssignment)
    // TODO PackCumulsOfOptimizerDimensionsFromAssignment
    // TODO AddLocalSearchFilter
    .define_method("start", &RoutingModel::Start)
    .define_method("end", &RoutingModel::End)
    .define_method("start?", &RoutingModel::IsStart)
    .define_method("end?", &RoutingModel::IsEnd)
    .define_method("vehicle_index", &RoutingModel::VehicleIndex)
    .define_method("next", &RoutingModel::Next)
    .define_method("vehicle_used?", &RoutingModel::IsVehicleUsed)
    .define_method("next_var", &RoutingModel::NextVar)
    .define_method("active_var", &RoutingModel::ActiveVar)
    .define_method("active_vehicle_var", &RoutingModel::ActiveVehicleVar)
    .define_method("vehicle_route_considered_var", &RoutingModel::VehicleRouteConsideredVar)
    .define_method("vehicle_var", &RoutingModel::VehicleVar)
    .define_method("resource_var", &RoutingModel::ResourceVar)
    .define_method("cost_var", &RoutingModel::CostVar)
    .define_method("arc_cost_for_vehicle", &RoutingModel::GetArcCostForVehicle)
    .define_method("costs_are_homogeneous_across_vehicles?", &RoutingModel::CostsAreHomogeneousAcrossVehicles)
    .define_method("homogeneous_cost", &RoutingModel::GetHomogeneousCost)
    .define_method("arc_cost_for_first_solution", &RoutingModel::GetArcCostForFirstSolution)
    .define_method("cost_classes_count", &RoutingModel::GetCostClassesCount)
    .define_method("non_zero_cost_classes_count", &RoutingModel::GetNonZeroCostClassesCount)
    .define_method("vehicle_classes_count", &RoutingModel::GetVehicleClassesCount)
    .define_method("arc_is_more_constrained_than_arc?", &RoutingModel::ArcIsMoreConstrainedThanArc)
    .define_method("solver", &RoutingModel::solver)
    .define_method("nodes", &RoutingModel::nodes)
    .define_method("vehicles", &RoutingModel::vehicles)
    .define_method("size", &RoutingModel::Size)
    .define_method("matching_model?", &RoutingModel::IsMatchingModel);
}
