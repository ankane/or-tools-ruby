// or-tools
#include <ortools/algorithms/knapsack_solver.h>
#include <ortools/graph/assignment.h>
#include <ortools/graph/max_flow.h>
#include <ortools/graph/min_cost_flow.h>
#include <ortools/linear_solver/linear_solver.h>
#include <ortools/sat/cp_model.h>

// rice
#include <rice/Array.hpp>
#include <rice/Class.hpp>
#include <rice/Constructor.hpp>
#include <rice/Hash.hpp>
#include <rice/Module.hpp>
#include <rice/Symbol.hpp>

using operations_research::ArcIndex;
using operations_research::Domain;
using operations_research::FlowQuantity;
using operations_research::KnapsackSolver;
using operations_research::MPConstraint;
using operations_research::MPObjective;
using operations_research::MPSolver;
using operations_research::MPVariable;
using operations_research::NodeIndex;
using operations_research::SimpleLinearSumAssignment;
using operations_research::SimpleMaxFlow;
using operations_research::SimpleMinCostFlow;

using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::CpSolverStatus;
using operations_research::sat::IntVar;
using operations_research::sat::SolutionIntegerValue;

using Rice::Array;
using Rice::Class;
using Rice::Constructor;
using Rice::Hash;
using Rice::Module;
using Rice::Object;
using Rice::Symbol;
using Rice::define_module;
using Rice::define_class_under;

template<>
inline
KnapsackSolver::SolverType from_ruby<KnapsackSolver::SolverType>(Object x)
{
  std::string s = Symbol(x).str();
  if (s == "branch_and_bound") {
    return KnapsackSolver::KNAPSACK_MULTIDIMENSION_BRANCH_AND_BOUND_SOLVER;
  } else {
    throw std::runtime_error("Unknown solver type: " + s);
  }
}

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

Class rb_cMPVariable;
Class rb_cMPConstraint;
Class rb_cMPObjective;

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

extern "C"
void Init_ext()
{
  Module rb_mORTools = define_module("ORTools");

  rb_cMPVariable = define_class_under<MPVariable>(rb_mORTools, "MPVariable")
    .define_method("name", &MPVariable::name)
    .define_method("solution_value", &MPVariable::solution_value);

  rb_cMPConstraint = define_class_under<MPConstraint>(rb_mORTools, "MPConstraint")
    .define_method("set_coefficient", &MPConstraint::SetCoefficient);

  rb_cMPObjective = define_class_under<MPObjective>(rb_mORTools, "MPObjective")
    .define_method("value", &MPObjective::Value)
    .define_method("set_coefficient", &MPObjective::SetCoefficient)
    .define_method("set_maximization", &MPObjective::SetMaximization);

  define_class_under<MPSolver>(rb_mORTools, "Solver")
    .define_constructor(Constructor<MPSolver, std::string, MPSolver::OptimizationProblemType>())
    .define_method("infinity", &MPSolver::infinity)
    .define_method("int_var", &MPSolver::MakeIntVar)
    .define_method("num_var", &MPSolver::MakeNumVar)
    .define_method("num_variables", &MPSolver::NumVariables)
    .define_method("num_constraints", &MPSolver::NumConstraints)
    .define_method("wall_time", &MPSolver::wall_time)
    .define_method("iterations", &MPSolver::iterations)
    .define_method("nodes", &MPSolver::nodes)
    .define_method("objective", &MPSolver::MutableObjective)
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

  define_class_under<IntVar>(rb_mORTools, "IntVar");

  define_class_under<CpModelBuilder>(rb_mORTools, "CpModel")
    .define_constructor(Constructor<CpModelBuilder>())
    .define_method(
      "new_int_var",
      *[](CpModelBuilder& self, int64 start, int64 end, std::string name) {
        const Domain domain(start, end);
        return self.NewIntVar(domain).WithName(name);
      })
    .define_method(
      "add_not_equal",
      *[](CpModelBuilder& self, IntVar x, IntVar y) {
        // TODO return value
        self.AddNotEqual(x, y);
      });

  define_class_under(rb_mORTools, "CpSolver")
    .define_method(
      "_solve",
      *[](Object self, CpModelBuilder& model) {
        return Solve(model.Build());
      })
    .define_method(
      "_solution_integer_value",
      *[](Object self, CpSolverResponse& response, IntVar& x) {
        return SolutionIntegerValue(response, x);
      });

  define_class_under<CpSolverResponse>(rb_mORTools, "CpSolverResponse")
    .define_method(
      "status",
      *[](CpSolverResponse& self) {
        auto status = self.status();
        if (status == CpSolverStatus::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == CpSolverStatus::FEASIBLE) {
          return Symbol("feasible");
        } else if (status == CpSolverStatus::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == CpSolverStatus::MODEL_INVALID) {
          return Symbol("model_invalid");
        } else {
          throw std::runtime_error("Unknown solver status");
        }
      });

  define_class_under<KnapsackSolver>(rb_mORTools, "KnapsackSolver")
    .define_constructor(Constructor<KnapsackSolver, KnapsackSolver::SolverType, std::string>())
    .define_method("_solve", &KnapsackSolver::Solve)
    .define_method("best_solution_contains?", &KnapsackSolver::BestSolutionContains)
    .define_method(
      "init",
      *[](KnapsackSolver& self, Array rb_values, Array rb_weights, Array rb_capacities) {
        std::vector<int64> values;
        for (std::size_t i = 0; i < rb_values.size(); ++i) {
          values.push_back(from_ruby<int64>(rb_values[i]));
        }

        std::vector<std::vector<int64>> weights;
        for (std::size_t i = 0; i < rb_weights.size(); ++i) {
          Array rb_w = Array(rb_weights[i]);
          std::vector<int64> w;
          for (std::size_t j = 0; j < rb_w.size(); ++j) {
            w.push_back(from_ruby<int64>(rb_w[j]));
          }
          weights.push_back(w);
        }

        std::vector<int64> capacities;
        for (std::size_t i = 0; i < rb_capacities.size(); ++i) {
          capacities.push_back(from_ruby<int64>(rb_capacities[i]));
        }

        self.Init(values, weights, capacities);
      });

  define_class_under<SimpleMaxFlow>(rb_mORTools, "SimpleMaxFlow")
    .define_constructor(Constructor<SimpleMaxFlow>())
    .define_method("add_arc_with_capacity", &SimpleMaxFlow::AddArcWithCapacity)
    .define_method("num_nodes", &SimpleMaxFlow::NumNodes)
    .define_method("num_arcs", &SimpleMaxFlow::NumArcs)
    .define_method("tail", &SimpleMaxFlow::Tail)
    .define_method("head", &SimpleMaxFlow::Head)
    .define_method("capacity", &SimpleMaxFlow::Capacity)
    .define_method("optimal_flow", &SimpleMaxFlow::OptimalFlow)
    .define_method("flow", &SimpleMaxFlow::Flow)
    .define_method(
      "solve",
      *[](SimpleMaxFlow& self, NodeIndex source, NodeIndex sink) {
        auto status = self.Solve(source, sink);

        if (status == SimpleMaxFlow::Status::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == SimpleMaxFlow::Status::POSSIBLE_OVERFLOW) {
          return Symbol("possible_overflow");
        } else if (status == SimpleMaxFlow::Status::BAD_INPUT) {
          return Symbol("bad_input");
        } else if (status == SimpleMaxFlow::Status::BAD_RESULT) {
          return Symbol("bad_result");
        } else {
          throw std::runtime_error("Unknown status");
        }
      })
    .define_method(
      "source_side_min_cut",
      *[](SimpleMaxFlow& self) {
        std::vector<NodeIndex> result;
        self.GetSourceSideMinCut(&result);

        Array ret;
        for(auto const& it: result) {
          ret.push(it);
        }
        return ret;
      })
    .define_method(
      "sink_side_min_cut",
      *[](SimpleMaxFlow& self) {
        std::vector<NodeIndex> result;
        self.GetSinkSideMinCut(&result);

        Array ret;
        for(auto const& it: result) {
          ret.push(it);
        }
        return ret;
      });

  define_class_under<SimpleMinCostFlow>(rb_mORTools, "SimpleMinCostFlow")
    .define_constructor(Constructor<SimpleMinCostFlow>())
    .define_method("add_arc_with_capacity_and_unit_cost", &SimpleMinCostFlow::AddArcWithCapacityAndUnitCost)
    .define_method("set_node_supply", &SimpleMinCostFlow::SetNodeSupply)
    .define_method("optimal_cost", &SimpleMinCostFlow::OptimalCost)
    .define_method("maximum_flow", &SimpleMinCostFlow::MaximumFlow)
    .define_method("flow", &SimpleMinCostFlow::Flow)
    .define_method("num_nodes", &SimpleMinCostFlow::NumNodes)
    .define_method("num_arcs", &SimpleMinCostFlow::NumArcs)
    .define_method("tail", &SimpleMinCostFlow::Tail)
    .define_method("head", &SimpleMinCostFlow::Head)
    .define_method("capacity", &SimpleMinCostFlow::Capacity)
    .define_method("supply", &SimpleMinCostFlow::Supply)
    .define_method("unit_cost", &SimpleMinCostFlow::UnitCost)
    .define_method(
      "solve",
      *[](SimpleMinCostFlow& self) {
        auto status = self.Solve();

        if (status == SimpleMinCostFlow::Status::NOT_SOLVED) {
          return Symbol("not_solved");
        } else if (status == SimpleMinCostFlow::Status::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == SimpleMinCostFlow::Status::FEASIBLE) {
          return Symbol("feasible");
        } else if (status == SimpleMinCostFlow::Status::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == SimpleMinCostFlow::Status::UNBALANCED) {
          return Symbol("unbalanced");
        } else if (status == SimpleMinCostFlow::Status::BAD_RESULT) {
          return Symbol("bad_result");
        } else if (status == SimpleMinCostFlow::Status::BAD_COST_RANGE) {
          return Symbol("bad_cost_range");
        } else {
          throw std::runtime_error("Unknown status");
        }
      });

  define_class_under<SimpleLinearSumAssignment>(rb_mORTools, "LinearSumAssignment")
    .define_constructor(Constructor<SimpleLinearSumAssignment>())
    .define_method("add_arc_with_cost", &SimpleLinearSumAssignment::AddArcWithCost)
    .define_method("num_nodes", &SimpleLinearSumAssignment::NumNodes)
    .define_method("num_arcs", &SimpleLinearSumAssignment::NumArcs)
    .define_method("left_node", &SimpleLinearSumAssignment::LeftNode)
    .define_method("right_node", &SimpleLinearSumAssignment::RightNode)
    .define_method("cost", &SimpleLinearSumAssignment::Cost)
    .define_method("optimal_cost", &SimpleLinearSumAssignment::OptimalCost)
    .define_method("right_mate", &SimpleLinearSumAssignment::RightMate)
    .define_method("assignment_cost", &SimpleLinearSumAssignment::AssignmentCost)
    .define_method(
      "solve",
      *[](SimpleLinearSumAssignment& self) {
        auto status = self.Solve();

        if (status == SimpleLinearSumAssignment::Status::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == SimpleLinearSumAssignment::Status::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == SimpleLinearSumAssignment::Status::POSSIBLE_OVERFLOW) {
          return Symbol("possible_overflow");
        } else {
          throw std::runtime_error("Unknown status");
        }
      });
}
