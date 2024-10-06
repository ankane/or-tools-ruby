#include "absl/log/check.h"
#include "absl/status/statusor.h"
#include "ortools/base/init_google.h"
#include "ortools/math_opt/cpp/math_opt.h"

#include "ext.h"

using operations_research::math_opt::BoundedLinearExpression;
using operations_research::math_opt::Model;
using operations_research::math_opt::Variable;

void init_math_opt(Rice::Module& m) {
  auto mathopt = Rice::define_module_under(m, "MathOpt");

  Rice::define_class_under<Variable>(mathopt, "Variable");

  Rice::define_class_under<Model>(mathopt, "Model")
    .define_constructor(Rice::Constructor<Model, std::string>())
    .define_method("add_variable", &Model::AddContinuousVariable)
    .define_method(
      "add_linear_constraint",
      [](Model& self, const BoundedLinearExpression& bounded_expr, const std::string& name) {
        self.AddLinearConstraint(bounded_expr, name);
      });
}
