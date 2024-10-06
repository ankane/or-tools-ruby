#include "absl/log/check.h"
#include "absl/status/statusor.h"
#include "ortools/base/init_google.h"
#include "ortools/math_opt/cpp/math_opt.h"

#include "ext.h"

using operations_research::math_opt::LinearConstraint;
using operations_research::math_opt::Model;
using operations_research::math_opt::Solve;
using operations_research::math_opt::SolveArguments;
using operations_research::math_opt::SolveResult;
using operations_research::math_opt::SolverType;
using operations_research::math_opt::Variable;

void init_math_opt(Rice::Module& m) {
  auto mathopt = Rice::define_module_under(m, "MathOpt");

  Rice::define_class_under<Variable>(mathopt, "Variable")
    .define_method("id", &Variable::id)
    .define_method(
      "_eql?",
      [](Variable& self, Variable &other) {
        return (bool) (self == other);
      });

  Rice::define_class_under<LinearConstraint>(mathopt, "LinearConstraint");

  Rice::define_class_under<SolveResult>(mathopt, "SolveResult")
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
      [](Model& self) {
        SolveArguments args;
        return *Solve(self, SolverType::kGlop, args);
      });
}
