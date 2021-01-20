// or-tools
#include <ortools/base/version.h>
#include <ortools/constraint_solver/routing.h>
#include <ortools/constraint_solver/routing_parameters.h>
#include <ortools/linear_solver/linear_solver.h>

// rice
#include <rice/Array.hpp>
#include <rice/Class.hpp>
#include <rice/Constructor.hpp>
#include <rice/Hash.hpp>
#include <rice/Module.hpp>
#include <rice/String.hpp>
#include <rice/Symbol.hpp>

using operations_research::DefaultRoutingSearchParameters;
using operations_research::Domain;
using operations_research::FirstSolutionStrategy;
using operations_research::LinearExpr;
using operations_research::LinearRange;
using operations_research::LocalSearchMetaheuristic;
using operations_research::MPConstraint;
using operations_research::MPObjective;
using operations_research::MPSolver;
using operations_research::MPVariable;
using operations_research::RoutingDimension;
using operations_research::RoutingIndexManager;
using operations_research::RoutingModel;
using operations_research::RoutingNodeIndex;
using operations_research::RoutingSearchParameters;

using Rice::Array;
using Rice::Class;
using Rice::Constructor;
using Rice::Hash;
using Rice::Module;
using Rice::Object;
using Rice::String;
using Rice::Symbol;
using Rice::define_module;
using Rice::define_class_under;

template<>
inline
MPSolver::OptimizationProblemType from_ruby<MPSolver::OptimizationProblemType>(Object x)
{
  std::string s = Symbol(x).str();
  if (s == "glop") {
    return MPSolver::OptimizationProblemType::GLOP_LINEAR_PROGRAMMING;
  } else if (s == "cbc") {
    return MPSolver::OptimizationProblemType::CBC_MIXED_INTEGER_PROGRAMMING;
  } else {
    throw std::runtime_error("Unknown optimization problem type: " + s);
  }
}

template<>
inline
RoutingNodeIndex from_ruby<RoutingNodeIndex>(Object x)
{
  const RoutingNodeIndex index{from_ruby<int>(x)};
  return index;
}

template<>
inline
Object to_ruby<RoutingNodeIndex>(RoutingNodeIndex const &x)
{
  return to_ruby<int>(x.value());
}

std::vector<RoutingNodeIndex> nodeIndexVector(Array x) {
  std::vector<RoutingNodeIndex> res;
  for (auto const& v : x) {
    res.push_back(from_ruby<RoutingNodeIndex>(v));
  }
  return res;
}

// need a wrapper class due to const
class Assignment {
  const operations_research::Assignment* self;
  public:
    Assignment(const operations_research::Assignment* v) {
      self = v;
    }
    int64 ObjectiveValue() {
      return self->ObjectiveValue();
    }
    int64 Value(const operations_research::IntVar* const var) const {
      return self->Value(var);
    }
    int64 Min(const operations_research::IntVar* const var) const {
      return self->Min(var);
    }
    int64 Max(const operations_research::IntVar* const var) const {
      return self->Max(var);
    }
};

Class rb_cMPVariable;
Class rb_cMPConstraint;
Class rb_cMPObjective;
Class rb_cIntVar;
Class rb_cIntervalVar;
Class rb_cRoutingDimension;
Class rb_cConstraint;
Class rb_cSolver2;

template<>
inline
Object to_ruby<MPVariable*>(MPVariable* const &x)
{
  return Rice::Data_Object<MPVariable>(x, rb_cMPVariable, nullptr, nullptr);
}

template<>
inline
Object to_ruby<MPConstraint*>(MPConstraint* const &x)
{
  return Rice::Data_Object<MPConstraint>(x, rb_cMPConstraint, nullptr, nullptr);
}

template<>
inline
Object to_ruby<MPObjective*>(MPObjective* const &x)
{
  return Rice::Data_Object<MPObjective>(x, rb_cMPObjective, nullptr, nullptr);
}

template<>
inline
Object to_ruby<operations_research::IntVar*>(operations_research::IntVar* const &x)
{
  return Rice::Data_Object<operations_research::IntVar>(x, rb_cIntVar, nullptr, nullptr);
}

template<>
inline
Object to_ruby<operations_research::IntervalVar*>(operations_research::IntervalVar* const &x)
{
  return Rice::Data_Object<operations_research::IntervalVar>(x, rb_cIntervalVar, nullptr, nullptr);
}

template<>
inline
Object to_ruby<RoutingDimension*>(RoutingDimension* const &x)
{
  return Rice::Data_Object<RoutingDimension>(x, rb_cRoutingDimension, nullptr, nullptr);
}

template<>
inline
Object to_ruby<operations_research::Constraint*>(operations_research::Constraint* const &x)
{
  return Rice::Data_Object<operations_research::Constraint>(x, rb_cConstraint, nullptr, nullptr);
}

template<>
inline
Object to_ruby<operations_research::Solver*>(operations_research::Solver* const &x)
{
  return Rice::Data_Object<operations_research::Solver>(x, rb_cSolver2, nullptr, nullptr);
}

void init_routing(Rice::Module& m) {
  m.define_singleton_method("default_routing_search_parameters", &DefaultRoutingSearchParameters);

  Rice::define_class_under<RoutingSearchParameters>(m, "RoutingSearchParameters")
    .define_method(
      "first_solution_strategy=",
      *[](RoutingSearchParameters& self, Symbol value) {
        std::string s = Symbol(value).str();

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
      *[](RoutingSearchParameters& self, Symbol value) {
        std::string s = Symbol(value).str();

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
      *[](RoutingSearchParameters& self, bool value) {
        self.set_log_search(value);
      })
    .define_method(
      "solution_limit=",
      *[](RoutingSearchParameters& self, int64 value) {
        self.set_solution_limit(value);
      })
    .define_method(
      "time_limit=",
      *[](RoutingSearchParameters& self, int64 value) {
        self.mutable_time_limit()->set_seconds(value);
      })
    .define_method(
      "lns_time_limit=",
      *[](RoutingSearchParameters& self, int64 value) {
        self.mutable_lns_time_limit()->set_seconds(value);
      });

  rb_cMPVariable = Rice::define_class_under<MPVariable>(m, "MPVariable")
    .define_method("name", &MPVariable::name)
    .define_method("solution_value", &MPVariable::solution_value)
    .define_method(
      "+",
      *[](MPVariable& self, LinearExpr& other) {
        LinearExpr s(&self);
        return s + other;
      })
    .define_method(
      "-",
      *[](MPVariable& self, LinearExpr& other) {
        LinearExpr s(&self);
        return s - other;
      })
    .define_method(
      "*",
      *[](MPVariable& self, double other) {
        LinearExpr s(&self);
        return s * other;
      })
    .define_method(
      "inspect",
      *[](MPVariable& self) {
        return "#<ORTools::MPVariable @name=\"" + self.name() + "\">";
      });

  Rice::define_class_under<LinearExpr>(m, "LinearExpr")
    .define_constructor(Rice::Constructor<LinearExpr>())
    .define_method(
      "_add_linear_expr",
      *[](LinearExpr& self, LinearExpr& other) {
        return self + other;
      })
    .define_method(
      "_add_mp_variable",
      *[](LinearExpr& self, MPVariable &other) {
        LinearExpr o(&other);
        return self + o;
      })
    .define_method(
      "_gte_double",
      *[](LinearExpr& self, double other) {
        LinearExpr o(other);
        return self >= o;
      })
    .define_method(
      "_gte_linear_expr",
      *[](LinearExpr& self, LinearExpr& other) {
        return self >= other;
      })
    .define_method(
      "_lte_double",
      *[](LinearExpr& self, double other) {
        LinearExpr o(other);
        return self <= o;
      })
    .define_method(
      "_lte_linear_expr",
      *[](LinearExpr& self, LinearExpr& other) {
        return self <= other;
      })
    .define_method(
      "==",
      *[](LinearExpr& self, double other) {
        LinearExpr o(other);
        return self == o;
      })
    .define_method(
      "to_s",
      *[](LinearExpr& self) {
        return self.ToString();
      })
    .define_method(
      "inspect",
      *[](LinearExpr& self) {
        return "#<ORTools::LinearExpr \"" + self.ToString() + "\">";
      });

  Rice::define_class_under<LinearRange>(m, "LinearRange");

  rb_cMPConstraint = Rice::define_class_under<MPConstraint>(m, "MPConstraint")
    .define_method("set_coefficient", &MPConstraint::SetCoefficient);

  rb_cMPObjective = Rice::define_class_under<MPObjective>(m, "MPObjective")
    .define_method("value", &MPObjective::Value)
    .define_method("set_coefficient", &MPObjective::SetCoefficient)
    .define_method("set_maximization", &MPObjective::SetMaximization);

  Rice::define_class_under<MPSolver>(m, "Solver")
    .define_constructor(Rice::Constructor<MPSolver, std::string, MPSolver::OptimizationProblemType>())
    .define_method("infinity", &MPSolver::infinity)
    .define_method(
      "int_var",
      *[](MPSolver& self, double min, double max, const std::string& name) {
        return self.MakeIntVar(min, max, name);
      })
    .define_method("num_var", &MPSolver::MakeNumVar)
    .define_method("bool_var", &MPSolver::MakeBoolVar)
    .define_method("num_variables", &MPSolver::NumVariables)
    .define_method("num_constraints", &MPSolver::NumConstraints)
    .define_method("wall_time", &MPSolver::wall_time)
    .define_method("iterations", &MPSolver::iterations)
    .define_method("nodes", &MPSolver::nodes)
    .define_method("objective", &MPSolver::MutableObjective)
    .define_method(
      "maximize",
      *[](MPSolver& self, LinearExpr& expr) {
        return self.MutableObjective()->MaximizeLinearExpr(expr);
      })
    .define_method(
      "minimize",
      *[](MPSolver& self, LinearExpr& expr) {
        return self.MutableObjective()->MinimizeLinearExpr(expr);
      })
    .define_method(
      "add",
      *[](MPSolver& self, const LinearRange& range) {
        return self.MakeRowConstraint(range);
      })
    .define_method(
      "constraint",
      *[](MPSolver& self, double lb, double ub) {
        return self.MakeRowConstraint(lb, ub);
      })
    .define_method(
      "solve",
      *[](MPSolver& self) {
        auto status = self.Solve();

        if (status == MPSolver::ResultStatus::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == MPSolver::ResultStatus::FEASIBLE) {
          return Symbol("feasible");
        } else if (status == MPSolver::ResultStatus::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == MPSolver::ResultStatus::UNBOUNDED) {
          return Symbol("unbounded");
        } else if (status == MPSolver::ResultStatus::ABNORMAL) {
          return Symbol("abnormal");
        } else if (status == MPSolver::ResultStatus::MODEL_INVALID) {
          return Symbol("model_invalid");
        } else if (status == MPSolver::ResultStatus::NOT_SOLVED) {
          return Symbol("not_solved");
        } else {
          throw std::runtime_error("Unknown status");
        }
      });

  Rice::define_class_under<RoutingIndexManager>(m, "RoutingIndexManager")
    .define_singleton_method(
      "_new_depot",
      *[](int num_nodes, int num_vehicles, RoutingNodeIndex depot) {
        return RoutingIndexManager(num_nodes, num_vehicles, depot);
      })
    .define_singleton_method(
      "_new_starts_ends",
      *[](int num_nodes, int num_vehicles, Array starts, Array ends) {
        return RoutingIndexManager(num_nodes, num_vehicles, nodeIndexVector(starts), nodeIndexVector(ends));
      })
    .define_method("index_to_node", &RoutingIndexManager::IndexToNode)
    .define_method("node_to_index", &RoutingIndexManager::NodeToIndex);

  Rice::define_class_under<Assignment>(m, "Assignment")
    .define_method("objective_value", &Assignment::ObjectiveValue)
    .define_method("value", &Assignment::Value)
    .define_method("min", &Assignment::Min)
    .define_method("max", &Assignment::Max);

  // not to be confused with operations_research::sat::IntVar
  rb_cIntVar = Rice::define_class_under<operations_research::IntVar>(m, "IntVar")
    .define_method(
      "set_range",
      *[](operations_research::IntVar& self, int64 new_min, int64 new_max) {
        self.SetRange(new_min, new_max);
      });

  rb_cIntervalVar = Rice::define_class_under<operations_research::IntervalVar>(m, "IntervalVar");

  rb_cRoutingDimension = Rice::define_class_under<RoutingDimension>(m, "RoutingDimension")
    .define_method("global_span_cost_coefficient=", &RoutingDimension::SetGlobalSpanCostCoefficient)
    .define_method("cumul_var", &RoutingDimension::CumulVar);

  rb_cConstraint = Rice::define_class_under<operations_research::Constraint>(m, "Constraint");

  rb_cSolver2 = Rice::define_class_under<operations_research::Solver>(m, "Solver2")
    .define_method(
      "add",
      *[](operations_research::Solver& self, Object o) {
        operations_research::Constraint* constraint;
        if (o.respond_to("left")) {
          operations_research::IntExpr* left(from_ruby<operations_research::IntVar*>(o.call("left")));
          operations_research::IntExpr* right(from_ruby<operations_research::IntVar*>(o.call("right")));
          auto op = o.call("operator").to_s().str();
          if (op == "==") {
            constraint = self.MakeEquality(left, right);
          } else if (op == "<=") {
            constraint = self.MakeLessOrEqual(left, right);
          } else {
            throw std::runtime_error("Unknown operator");
          }
        } else {
          constraint = from_ruby<operations_research::Constraint*>(o);
        }
        self.AddConstraint(constraint);
      })
    .define_method(
      "fixed_duration_interval_var",
      *[](operations_research::Solver& self, operations_research::IntVar* const start_variable, int64 duration, const std::string& name) {
        return self.MakeFixedDurationIntervalVar(start_variable, duration, name);
      })
    .define_method(
      "cumulative",
      *[](operations_research::Solver& self, Array rb_intervals, Array rb_demands, int64 capacity, const std::string& name) {
        std::vector<operations_research::IntervalVar*> intervals;
        for (std::size_t i = 0; i < rb_intervals.size(); ++i) {
          intervals.push_back(from_ruby<operations_research::IntervalVar*>(rb_intervals[i]));
        }

        std::vector<int64> demands;
        for (std::size_t i = 0; i < rb_demands.size(); ++i) {
          demands.push_back(from_ruby<int64>(rb_demands[i]));
        }

        return self.MakeCumulative(intervals, demands, capacity, name);
      });

  Rice::define_class_under<RoutingModel>(m, "RoutingModel")
    .define_constructor(Rice::Constructor<RoutingModel, RoutingIndexManager>())
    .define_method(
      "register_transit_callback",
      *[](RoutingModel& self, Object callback) {
        return self.RegisterTransitCallback(
          [callback](int64 from_index, int64 to_index) -> int64 {
            return from_ruby<int64>(callback.call("call", from_index, to_index));
          }
        );
      })
    .define_method(
      "register_unary_transit_callback",
      *[](RoutingModel& self, Object callback) {
        return self.RegisterUnaryTransitCallback(
          [callback](int64 from_index) -> int64 {
            return from_ruby<int64>(callback.call("call", from_index));
          }
        );
      })
    .define_method("depot", &RoutingModel::GetDepot)
    .define_method("size", &RoutingModel::Size)
    .define_method("status", *[](RoutingModel& self) {
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
      *[](RoutingModel& self, int evaluator_index, int64 slack_max, Array vc, bool fix_start_cumul_to_zero, const std::string& name) {
        std::vector<int64> vehicle_capacities;
        for (std::size_t i = 0; i < vc.size(); ++i) {
          vehicle_capacities.push_back(from_ruby<int64>(vc[i]));
        }
        self.AddDimensionWithVehicleCapacity(evaluator_index, slack_max, vehicle_capacities, fix_start_cumul_to_zero, name);
      })
    .define_method(
      "add_dimension_with_vehicle_transits",
      *[](RoutingModel& self, Array rb_indices, int64 slack_max, int64 capacity, bool fix_start_cumul_to_zero, const std::string& name) {
        std::vector<int> evaluator_indices;
        for (std::size_t i = 0; i < rb_indices.size(); ++i) {
          evaluator_indices.push_back(from_ruby<int>(rb_indices[i]));
        }
        self.AddDimensionWithVehicleTransits(evaluator_indices, slack_max, capacity, fix_start_cumul_to_zero, name);
      })
    .define_method(
      "add_disjunction",
      *[](RoutingModel& self, Array rb_indices, int64 penalty) {
        std::vector<int64> indices;
        for (std::size_t i = 0; i < rb_indices.size(); ++i) {
          indices.push_back(from_ruby<int64>(rb_indices[i]));
        }
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
      *[](RoutingModel& self, const RoutingSearchParameters& search_parameters) {
        auto assignment = self.SolveWithParameters(search_parameters);
        // std::cout << assignment->DebugString();
        return (Assignment) assignment;
      });
}
