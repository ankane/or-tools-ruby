#include <memory>
#include <string>

#include <ortools/linear_solver/linear_solver.h>
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using operations_research::MPConstraint;
using operations_research::MPObjective;
using operations_research::MPSolverParameters;
using operations_research::MPSolver;
using operations_research::MPVariable;

using Rice::Array;
using Rice::Class;
using Rice::Module;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

namespace Rice::detail {
  template<>
  struct Type<MPSolver::OptimizationProblemType> {
    static bool verify() { return true; }
  };

  template<>
  struct From_Ruby<MPSolver::OptimizationProblemType> {
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg) { }

    Convertible is_convertible(VALUE value) { return Convertible::Cast; }

    static MPSolver::OptimizationProblemType convert(VALUE x) {
      auto s = Symbol(x).str();
      if (s == "glop") {
        return MPSolver::OptimizationProblemType::GLOP_LINEAR_PROGRAMMING;
      } else if (s == "cbc") {
        return MPSolver::OptimizationProblemType::CBC_MIXED_INTEGER_PROGRAMMING;
      } else {
        throw std::runtime_error("Unknown optimization problem type: " + s);
      }
    }

  private:
    Arg* arg_ = nullptr;
  };
} // namespace Rice::detail

void init_linear(Rice::Module& m) {
  Rice::define_class_under<MPVariable>(m, "MPVariable")
    .define_method("name", &MPVariable::name)
    .define_method("solution_value", &MPVariable::solution_value);

  Rice::define_class_under<MPConstraint>(m, "MPConstraint")
    .define_method("set_coefficient", &MPConstraint::SetCoefficient);

  Rice::define_class_under<MPObjective>(m, "MPObjective")
    .define_method("value", &MPObjective::Value)
    .define_method("clear", &MPObjective::Clear)
    .define_method("set_coefficient", &MPObjective::SetCoefficient)
    .define_method("set_offset", &MPObjective::SetOffset)
    .define_method("set_maximization", &MPObjective::SetMaximization)
    .define_method("best_bound", &MPObjective::BestBound)
    .define_method("set_minimization", &MPObjective::SetMinimization);

  Rice::define_class_under<MPSolverParameters>(m, "MPSolverParameters")
    .define_constructor(Rice::Constructor<MPSolverParameters>())
    .define_method("reset", &MPSolverParameters::Reset)
    .define_method(
      "relative_mip_gap=",
      [](MPSolverParameters& self, double relative_mip_gap) {
        self.SetDoubleParam(MPSolverParameters::DoubleParam::RELATIVE_MIP_GAP, relative_mip_gap);
      })
    .define_method(
      "relative_mip_gap",
      [](MPSolverParameters& self) {
        return self.GetDoubleParam(MPSolverParameters::DoubleParam::RELATIVE_MIP_GAP);
      })
    .define_method(
      "primal_tolerance=",
      [](MPSolverParameters& self, double primal_tolerance) {
        self.SetDoubleParam(MPSolverParameters::DoubleParam::PRIMAL_TOLERANCE, primal_tolerance);
      })
    .define_method(
      "primal_tolerance",
      [](MPSolverParameters& self) {
        return self.GetDoubleParam(MPSolverParameters::DoubleParam::PRIMAL_TOLERANCE);
      })
    .define_method(
      "dual_tolerance=",
      [](MPSolverParameters& self, double dual_tolerance) {
        self.SetDoubleParam(MPSolverParameters::DoubleParam::DUAL_TOLERANCE, dual_tolerance);
      })
    .define_method(
      "dual_tolerance",
      [](MPSolverParameters& self) {
        return self.GetDoubleParam(MPSolverParameters::DoubleParam::DUAL_TOLERANCE);
      })
    .define_method(
      "presolve=",
      [](MPSolverParameters& self, bool value) {
        int presolve;
        if (value) {
          presolve = MPSolverParameters::PresolveValues::PRESOLVE_ON;
        } else {
          presolve = MPSolverParameters::PresolveValues::PRESOLVE_OFF;
        }
        self.SetIntegerParam(MPSolverParameters::IntegerParam::PRESOLVE, presolve);
      })
    .define_method(
      "presolve",
      [](MPSolverParameters& self) {
        int presolve = self.GetIntegerParam(MPSolverParameters::IntegerParam::PRESOLVE);
        if (presolve == MPSolverParameters::PresolveValues::PRESOLVE_ON) {
          return Rice::True;
        } else if (presolve == MPSolverParameters::PresolveValues::PRESOLVE_OFF) {
          return Rice::False;
        } else {
          return Rice::Nil;
        }
      })
    .define_method(
      "incrementality=",
      [](MPSolverParameters& self, bool value) {
        int incrementality;
        if (value) {
          incrementality = MPSolverParameters::IncrementalityValues::INCREMENTALITY_ON;
        } else {
          incrementality = MPSolverParameters::IncrementalityValues::INCREMENTALITY_OFF;
        }
        self.SetIntegerParam(MPSolverParameters::IntegerParam::INCREMENTALITY, incrementality);
      })
    .define_method(
      "incrementality",
      [](MPSolverParameters& self) {
        int incrementality = self.GetIntegerParam(MPSolverParameters::IntegerParam::INCREMENTALITY);
        if (incrementality == MPSolverParameters::IncrementalityValues::INCREMENTALITY_ON) {
          return Rice::True;
        } else if (incrementality == MPSolverParameters::IncrementalityValues::INCREMENTALITY_OFF) {
          return Rice::False;
        } else {
          return Rice::Nil;
        }
      })
    .define_method(
      "scaling=",
      [](MPSolverParameters& self, bool value) {
        int scaling;
        if (value) {
          scaling = MPSolverParameters::ScalingValues::SCALING_ON;
        } else {
          scaling = MPSolverParameters::ScalingValues::SCALING_OFF;
        }
        self.SetIntegerParam(MPSolverParameters::IntegerParam::SCALING, scaling);
      })
    .define_method(
      "scaling",
      [](MPSolverParameters& self) {
        int scaling = self.GetIntegerParam(MPSolverParameters::IntegerParam::SCALING);
        if (scaling == MPSolverParameters::ScalingValues::SCALING_ON) {
          return Rice::True;
        } else if (scaling == MPSolverParameters::ScalingValues::SCALING_OFF) {
          return Rice::False;
        } else {
          return Rice::Nil;
        }
      });

  Rice::define_class_under<MPSolver>(m, "Solver")
    .define_singleton_function(
      "_new",
      [](const std::string& name, MPSolver::OptimizationProblemType problem_type) {
        std::unique_ptr<MPSolver> solver(new MPSolver(name, problem_type));
        if (!solver) {
          throw std::runtime_error("Unrecognized solver type");
        }
        return solver;
      })
    .define_singleton_function(
      "_create",
      [](const std::string& solver_id) {
        std::unique_ptr<MPSolver> solver(MPSolver::CreateSolver(solver_id));
        if (!solver) {
          throw std::runtime_error("Unrecognized solver type");
        }
        return solver;
      })
    .define_method(
      "time_limit=",
      [](MPSolver& self, double time_limit) {
        // use milliseconds to match Python
        self.SetTimeLimit(absl::Milliseconds(time_limit));
      })
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
      "_solve",
      [](MPSolver& self, MPSolverParameters& params) {
        auto status = self.Solve(params);

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
