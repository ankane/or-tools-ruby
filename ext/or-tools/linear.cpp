#include <ortools/linear_solver/linear_solver.h>

#include "ext.h"

using operations_research::LinearExpr;
using operations_research::LinearRange;
using operations_research::MPConstraint;
using operations_research::MPObjective;
using operations_research::MPSolver;
using operations_research::MPVariable;

using Rice::Array;
using Rice::Class;
using Rice::Module;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

namespace Rice::detail
{
  template<>
  struct Type<MPSolver::OptimizationProblemType>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  struct From_Ruby<MPSolver::OptimizationProblemType>
  {
    static MPSolver::OptimizationProblemType convert(VALUE x)
    {
      auto s = Symbol(x).str();
      if (s == "glop") {
        return MPSolver::OptimizationProblemType::GLOP_LINEAR_PROGRAMMING;
      } else if (s == "cbc") {
        return MPSolver::OptimizationProblemType::CBC_MIXED_INTEGER_PROGRAMMING;
      } else {
        throw std::runtime_error("Unknown optimization problem type: " + s);
      }
    }
  };
}

void init_linear(Rice::Module& m) {
  Rice::define_class_under<LinearRange>(m, "LinearRange");

  // TODO remove in 0.7.0
  auto rb_cLinearExpr = Rice::define_class_under<LinearExpr>(m, "LinearExpr");
  rb_cLinearExpr.define_constructor(Rice::Constructor<LinearExpr>());

  Rice::define_class_under<MPVariable, LinearExpr>(m, "MPVariable")
    .define_method("name", &MPVariable::name)
    .define_method("solution_value", &MPVariable::solution_value);

  Rice::define_class_under<MPConstraint>(m, "MPConstraint")
    .define_method("set_coefficient", &MPConstraint::SetCoefficient);

  Rice::define_class_under<MPObjective>(m, "MPObjective")
    .define_method("value", &MPObjective::Value)
    .define_method("set_coefficient", &MPObjective::SetCoefficient)
    .define_method("set_maximization", &MPObjective::SetMaximization)
    .define_method("set_minimization", &MPObjective::SetMinimization);

  Rice::define_class_under<MPSolver>(m, "Solver")
    .define_constructor(Rice::Constructor<MPSolver, std::string, MPSolver::OptimizationProblemType>())
    .define_method(
      "infinity",
      [](MPSolver& self) {
        return self.infinity();
      })
    .define_method(
      "int_var",
      [](MPSolver& self, double min, double max, const std::string& name) {
        return self.MakeIntVar(min, max, name);
      })
    .define_method("num_var", &MPSolver::MakeNumVar)
    .define_method("bool_var", &MPSolver::MakeBoolVar)
    .define_method("num_variables", &MPSolver::NumVariables)
    .define_method("num_constraints", &MPSolver::NumConstraints)
    .define_method("wall_time", &MPSolver::wall_time)
    .define_method("enable_output", &MPSolver::EnableOutput)
    .define_method("suppress_output", &MPSolver::SuppressOutput)
    .define_method("iterations", &MPSolver::iterations)
    .define_method("nodes", &MPSolver::nodes)
    .define_method("objective", &MPSolver::MutableObjective)
    .define_method(
      "constraint",
      [](MPSolver& self, double lb, double ub) {
        return self.MakeRowConstraint(lb, ub);
      })
    .define_method(
      "solve",
      [](MPSolver& self) {
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
      })
    .define_method(
      "export_model_as_lp_format",
      [](MPSolver& self, bool obfuscate) {
        std::string model_str;
        if (!self.ExportModelAsLpFormat(obfuscate, &model_str)) {
          throw std::runtime_error("Export failed");
        }
        return model_str;
      })
    .define_method(
      "export_model_as_mps_format",
      [](MPSolver& self, bool fixed_format, bool obfuscate) {
        std::string model_str;
        if (!self.ExportModelAsMpsFormat(fixed_format, obfuscate, &model_str)) {
          throw std::runtime_error("Export failed");
        }
        return model_str;
      });
}
