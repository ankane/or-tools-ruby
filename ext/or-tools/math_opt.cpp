#include <string>

#include <absl/log/check.h>
#include <absl/status/statusor.h>
#include <ortools/base/init_google.h>
#include <ortools/math_opt/cpp/math_opt.h>
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using operations_research::math_opt::LinearConstraint;
using operations_research::math_opt::Model;
using operations_research::math_opt::Solve;
using operations_research::math_opt::SolveArguments;
using operations_research::math_opt::SolveResult;
using operations_research::math_opt::SolverType;
using operations_research::math_opt::Termination;
using operations_research::math_opt::TerminationReason;
using operations_research::math_opt::Variable;

namespace Rice::detail {
  template<>
  struct Type<SolverType> {
    static bool verify() { return true; }
  };

  template<>
  struct From_Ruby<SolverType> {
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg) { }

    Convertible is_convertible(VALUE value) { return Convertible::Cast; }

    static SolverType convert(VALUE x) {
      auto s = Symbol(x).str();
      if (s == "gscip") {
        return SolverType::kGscip;
      } else if (s == "gurobi") {
        return SolverType::kGurobi;
      } else if (s == "glop") {
        return SolverType::kGlop;
      } else if (s == "cpsat") {
        return SolverType::kCpSat;
      } else if (s == "pdlp") {
        return SolverType::kPdlp;
      } else if (s == "glpk") {
        return SolverType::kGlpk;
      } else if (s == "ecos") {
        return SolverType::kEcos;
      } else if (s == "scs") {
        return SolverType::kScs;
      } else if (s == "highs") {
        return SolverType::kHighs;
      } else if (s == "santorini") {
        return SolverType::kSantorini;
      } else {
        throw std::runtime_error("Unknown solver type: " + s);
      }
    }

  private:
    Arg* arg_ = nullptr;
  };
} // namespace Rice::detail

void init_math_opt(Rice::Module& m) {
  auto mathopt = Rice::define_module_under(m, "MathOpt");

  Rice::define_class_under<Variable>(mathopt, "Variable")
    .define_method("id", &Variable::id)
    .define_method(
      "name",
      [](Variable& self) {
        return std::string(self.name());
      })
    .define_method(
      "_eql?",
      [](Variable& self, Variable &other) {
        return static_cast<bool>(self == other);
      });

  Rice::define_class_under<LinearConstraint>(mathopt, "LinearConstraint");

  Rice::define_class_under<Termination>(mathopt, "Termination")
    .define_method(
      "reason",
      [](Termination& self) {
        auto reason = self.reason;

        if (reason == TerminationReason::kOptimal) {
          return Rice::Symbol("optimal");
        } else if (reason == TerminationReason::kInfeasible) {
          return Rice::Symbol("infeasible");
        } else if (reason == TerminationReason::kUnbounded) {
          return Rice::Symbol("unbounded");
        } else if (reason == TerminationReason::kInfeasibleOrUnbounded) {
          return Rice::Symbol("infeasible_or_unbounded");
        } else if (reason == TerminationReason::kImprecise) {
          return Rice::Symbol("imprecise");
        } else if (reason == TerminationReason::kFeasible) {
          return Rice::Symbol("feasible");
        } else if (reason == TerminationReason::kNoSolutionFound) {
          return Rice::Symbol("no_solution_found");
        } else if (reason == TerminationReason::kNumericalError) {
          return Rice::Symbol("numerical_error");
        } else if (reason == TerminationReason::kOtherError) {
          return Rice::Symbol("other");
        } else {
          throw std::runtime_error("Unknown termination reason");
        }
      });

  Rice::define_class_under<SolveResult>(mathopt, "SolveResult")
    .define_method(
      "termination",
      [](SolveResult& self) {
        return self.termination;
      })
    .define_method(
      "objective_value",
      [](SolveResult& self) {
        return self.objective_value();
      })
    .define_method(
      "variable_values",
      [](SolveResult& self) {
        Rice::Hash map;
        for (auto& [k, v] : self.variable_values()) {
          map[k] = v;
        }
        return map;
      });

  Rice::define_class_under<Model>(mathopt, "Model")
    .define_constructor(Rice::Constructor<Model, std::string>())
    .define_method("add_variable", &Model::AddContinuousVariable)
    .define_method("add_integer_variable", &Model::AddIntegerVariable)
    .define_method("add_binary_variable", &Model::AddBinaryVariable)
    .define_method(
      "_add_linear_constraint",
      [](Model& self) {
        return self.AddLinearConstraint();
      })
    .define_method(
      "_set_upper_bound",
      [](Model& self, LinearConstraint constraint, double upper_bound) {
        self.set_upper_bound(constraint, upper_bound);
      })
    .define_method(
      "_set_lower_bound",
      [](Model& self, LinearConstraint constraint, double upper_bound) {
        self.set_lower_bound(constraint, upper_bound);
      })
    .define_method("_set_coefficient", &Model::set_coefficient)
    .define_method(
      "_set_objective_coefficient",
      [](Model& self, Variable variable, double value) {
        self.set_objective_coefficient(variable, value);
      })
    .define_method("_clear_objective", &Model::clear_objective)
    .define_method(
      "_set_objective_offset",
      [](Model& self, double value) {
        self.set_objective_offset(value);
      })
    .define_method(
      "_set_maximize",
      [](Model& self) {
        self.set_maximize();
      })
    .define_method(
      "_set_minimize",
      [](Model& self) {
        self.set_minimize();
      })
    .define_method(
      "_solve",
      [](Model& self, SolverType solver_type) {
        SolveArguments args;
        auto result = Solve(self, solver_type, args);

        if (!result.ok()) {
          throw std::invalid_argument(std::string{result.status().message()});
        }

        return *result;
      });
}
