#include <ortools/constraint_solver/routing.h>
#include <ortools/constraint_solver/routing_parameters.h>

#include "ext.h"

using operations_research::Assignment;
using operations_research::DefaultRoutingSearchParameters;
using operations_research::FirstSolutionStrategy;
using operations_research::LocalSearchMetaheuristic;
using operations_research::RoutingDimension;
using operations_research::RoutingIndexManager;
using operations_research::RoutingModel;
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
    .define_method(
      "set_range",
      [](operations_research::IntVar& self, int64_t new_min, int64_t new_max) {
        self.SetRange(new_min, new_max);
      });

  Rice::define_class_under<operations_research::IntervalVar>(m, "IntervalVar");

  Rice::define_class_under<RoutingDimension>(m, "RoutingDimension")
    .define_method("global_span_cost_coefficient=", &RoutingDimension::SetGlobalSpanCostCoefficient)
    .define_method("cumul_var", &RoutingDimension::CumulVar);

  Rice::define_class_under<operations_research::Constraint>(m, "Constraint");

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

  Rice::define_class_under<RoutingModel>(m, "RoutingModel")
    .define_constructor(Rice::Constructor<RoutingModel, RoutingIndexManager>())
    .define_method(
      "register_transit_callback",
      [](RoutingModel& self, Object callback) {
        return self.RegisterTransitCallback(
          [callback](int64_t from_index, int64_t to_index) -> int64_t {
            return Rice::detail::From_Ruby<int64_t>().convert(callback.call("call", from_index, to_index));
          }
        );
      })
    .define_method(
      "register_unary_transit_callback",
      [](RoutingModel& self, Object callback) {
        return self.RegisterUnaryTransitCallback(
          [callback](int64_t from_index) -> int64_t {
            return Rice::detail::From_Ruby<int64_t>().convert(callback.call("call", from_index));
          }
        );
      })
    .define_method("depot", &RoutingModel::GetDepot)
    .define_method("size", &RoutingModel::Size)
    .define_method("status", [](RoutingModel& self) {
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
    .define_method("vehicle_var", &RoutingModel::VehicleVar)
    .define_method("set_arc_cost_evaluator_of_all_vehicles", &RoutingModel::SetArcCostEvaluatorOfAllVehicles)
    .define_method("set_arc_cost_evaluator_of_vehicle", &RoutingModel::SetArcCostEvaluatorOfVehicle)
    .define_method("set_fixed_cost_of_all_vehicles", &RoutingModel::SetFixedCostOfAllVehicles)
    .define_method("set_fixed_cost_of_vehicle", &RoutingModel::SetFixedCostOfVehicle)
    .define_method("fixed_cost_of_vehicle", &RoutingModel::GetFixedCostOfVehicle)
    .define_method("add_dimension", &RoutingModel::AddDimension)
    .define_method(
      "add_dimension_with_vehicle_capacity",
      [](RoutingModel& self, int evaluator_index, int64_t slack_max, std::vector<int64_t> vehicle_capacities, bool fix_start_cumul_to_zero, const std::string& name) {
        self.AddDimensionWithVehicleCapacity(evaluator_index, slack_max, vehicle_capacities, fix_start_cumul_to_zero, name);
      })
    .define_method(
      "add_dimension_with_vehicle_transits",
      [](RoutingModel& self, std::vector<int> evaluator_indices, int64_t slack_max, int64_t capacity, bool fix_start_cumul_to_zero, const std::string& name) {
        self.AddDimensionWithVehicleTransits(evaluator_indices, slack_max, capacity, fix_start_cumul_to_zero, name);
      })
    .define_method(
      "add_disjunction",
      [](RoutingModel& self, std::vector<int64_t> indices, int64_t penalty) {
        self.AddDisjunction(indices, penalty);
      })
    .define_method("add_pickup_and_delivery", &RoutingModel::AddPickupAndDelivery)
    .define_method("solver", &RoutingModel::solver)
    .define_method("start", &RoutingModel::Start)
    .define_method("end", &RoutingModel::End)
    .define_method("start?", &RoutingModel::IsStart)
    .define_method("end?", &RoutingModel::IsEnd)
    .define_method("vehicle_index", &RoutingModel::VehicleIndex)
    .define_method("next", &RoutingModel::Next)
    .define_method("vehicle_used?", &RoutingModel::IsVehicleUsed)
    .define_method("next_var", &RoutingModel::NextVar)
    .define_method("arc_cost_for_vehicle", &RoutingModel::GetArcCostForVehicle)
    .define_method("mutable_dimension", &RoutingModel::GetMutableDimension)
    .define_method("add_variable_minimized_by_finalizer", &RoutingModel::AddVariableMinimizedByFinalizer)
    .define_method(
      "solve_with_parameters",
      [](RoutingModel& self, const RoutingSearchParameters& search_parameters) {
        return self.SolveWithParameters(search_parameters);
      });
}
