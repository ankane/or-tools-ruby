#include <google/protobuf/text_format.h>
#include <ortools/sat/cp_model.h>

#include "ext.h"

using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::CpSolverStatus;
using operations_research::sat::LinearExpr;
using operations_research::sat::IntVar;
using operations_research::sat::IntervalVar;
using operations_research::sat::Model;
using operations_research::sat::NewFeasibleSolutionObserver;
using operations_research::sat::SatParameters;
using operations_research::sat::SolutionBooleanValue;
using operations_research::sat::SolutionIntegerValue;

using Rice::Array;
using Rice::Class;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

Class rb_cBoolVar;
Class rb_cSatIntVar;

namespace Rice::detail
{
  template<>
  struct Type<LinearExpr>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class From_Ruby<LinearExpr>
  {
  public:
    LinearExpr convert(VALUE v)
    {
      Object x(v);
      LinearExpr expr;

      if (x.respond_to("to_i")) {
        expr = From_Ruby<int64_t>().convert(x.call("to_i").value());
      } else if (x.respond_to("vars")) {
        Array vars = x.call("vars");
        for (const auto& v : vars) {
          // TODO clean up
          auto cvar = (Array) v;
          Object var = cvar[0];
          auto coeff = From_Ruby<int64_t>().convert(cvar[1].value());

          if (var.is_a(rb_cBoolVar)) {
            expr.AddTerm(From_Ruby<BoolVar>().convert(var.value()), coeff);
          } else if (var.is_a(rb_cInteger)) {
            expr.AddConstant(From_Ruby<int64_t>().convert(var.value()) * coeff);
          } else {
            expr.AddTerm(From_Ruby<IntVar>().convert(var.value()), coeff);
          }
        }
      } else {
        if (x.is_a(rb_cBoolVar)) {
          expr = From_Ruby<BoolVar>().convert(x.value());
        } else {
          expr = From_Ruby<IntVar>().convert(x.value());
        }
      }

      return expr;
    }
  };

  template<>
  class From_Ruby<std::vector<BoolVar>>
  {
  public:
    std::vector<BoolVar> convert(VALUE v)
    {
      auto a = Array(v);
      std::vector<BoolVar> vec;
      vec.reserve(a.size());
      for (const Object v : a) {
        if (v.is_a(rb_cSatIntVar)) {
          vec.push_back(From_Ruby<IntVar>().convert(v.value()).ToBoolVar());
        } else {
          vec.push_back(From_Ruby<BoolVar>().convert(v.value()));
        }
      }
      return vec;
    }
  };
}

void init_constraint(Rice::Module& m) {
  rb_cSatIntVar = Rice::define_class_under<IntVar>(m, "SatIntVar")
    .define_method("name", &IntVar::Name);

  Rice::define_class_under<IntervalVar>(m, "SatIntervalVar")
    .define_method("name", &IntervalVar::Name);

  Rice::define_class_under<Constraint>(m, "SatConstraint")
    .define_method(
      "only_enforce_if",
      [](Constraint& self, Object literal) {
        if (literal.is_a(rb_cSatIntVar)) {
          return self.OnlyEnforceIf(Rice::detail::From_Ruby<IntVar>().convert(literal).ToBoolVar());
        } else if (literal.is_a(rb_cArray)) {
          // TODO support IntVarSpan
          return self.OnlyEnforceIf(Rice::detail::From_Ruby<std::vector<BoolVar>>().convert(literal));
        } else {
          return self.OnlyEnforceIf(Rice::detail::From_Ruby<BoolVar>().convert(literal));
        }
      });

  rb_cBoolVar = Rice::define_class_under<BoolVar>(m, "BoolVar")
    .define_method("name", &BoolVar::Name)
    .define_method("index", &BoolVar::index)
    .define_method("not", &BoolVar::Not)
    .define_method(
      "inspect",
      [](BoolVar& self) {
        String name(self.Name());
        return "#<ORTools::BoolVar @name=" + name.inspect().str() + ">";
      });

  Rice::define_class_under<SatParameters>(m, "SatParameters")
    .define_constructor(Rice::Constructor<SatParameters>())
    .define_method("max_time_in_seconds=",
    [](SatParameters& self, double value) {
      self.set_max_time_in_seconds(value);
    });

  Rice::define_class_under<CpModelBuilder>(m, "CpModel")
    .define_constructor(Rice::Constructor<CpModelBuilder>())
    .define_method(
      "new_int_var",
      [](CpModelBuilder& self, int64_t start, int64_t end, const std::string& name) {
        const operations_research::Domain domain(start, end);
        return self.NewIntVar(domain).WithName(name);
      })
    .define_method(
      "new_bool_var",
      [](CpModelBuilder& self, const std::string& name) {
        return self.NewBoolVar().WithName(name);
      })
    .define_method(
      "new_constant",
      [](CpModelBuilder& self, int64_t value) {
        return self.NewConstant(value);
      })
    .define_method(
      "true_var",
      [](CpModelBuilder& self) {
        return self.TrueVar();
      })
    .define_method(
      "false_var",
      [](CpModelBuilder& self) {
        return self.FalseVar();
      })
    .define_method(
      "new_interval_var",
      [](CpModelBuilder& self, IntVar start, IntVar size, IntVar end, const std::string& name) {
        return self.NewIntervalVar(start, size, end).WithName(name);
      })
    .define_method(
      "new_optional_interval_var",
      [](CpModelBuilder& self, IntVar start, IntVar size, IntVar end, BoolVar presence, const std::string& name) {
        return self.NewOptionalIntervalVar(start, size, end, presence).WithName(name);
      })
    .define_method(
      "add_bool_or",
      [](CpModelBuilder& self, std::vector<BoolVar> literals) {
        return self.AddBoolOr(literals);
      })
    .define_method(
      "add_bool_and",
      [](CpModelBuilder& self, std::vector<BoolVar> literals) {
        return self.AddBoolAnd(literals);
      })
    .define_method(
      "add_bool_xor",
      [](CpModelBuilder& self, std::vector<BoolVar> literals) {
        return self.AddBoolXor(literals);
      })
    .define_method(
      "add_implication",
      [](CpModelBuilder& self, BoolVar a, BoolVar b) {
        return self.AddImplication(a, b);
      })
    .define_method(
      "add_equality",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddEquality(x, y);
      })
    .define_method(
      "add_greater_or_equal",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddGreaterOrEqual(x, y);
      })
    .define_method(
      "add_greater_than",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddGreaterThan(x, y);
      })
    .define_method(
      "add_less_or_equal",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddLessOrEqual(x, y);
      })
    .define_method(
      "add_less_than",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddLessThan(x, y);
      })
    // TODO add domain
    // .define_method(
    //   "add_linear_constraint",
    //   [](CpModelBuilder& self, LinearExpr expr, Domain domain) {
    //     return self.AddLinearConstraint(expr, domain);
    //   })
    .define_method(
      "add_not_equal",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddNotEqual(x, y);
      })
    .define_method(
      "add_all_different",
      [](CpModelBuilder& self, std::vector<IntVar> vars) {
        return self.AddAllDifferent(vars);
      })
    .define_method(
      "add_inverse_constraint",
      [](CpModelBuilder& self, std::vector<IntVar> variables, std::vector<IntVar> inverse_variables) {
        return self.AddInverseConstraint(variables, inverse_variables);
      })
    .define_method(
      "add_min_equality",
      [](CpModelBuilder& self, IntVar target, std::vector<IntVar> vars) {
        return self.AddMinEquality(target, vars);
      })
    .define_method(
      "add_lin_min_equality",
      [](CpModelBuilder& self, LinearExpr target, std::vector<LinearExpr> exprs) {
        return self.AddLinMinEquality(target, exprs);
      })
    .define_method(
      "add_max_equality",
      [](CpModelBuilder& self, IntVar target, std::vector<IntVar> vars) {
        return self.AddMaxEquality(target, vars);
      })
    .define_method(
      "add_lin_max_equality",
      [](CpModelBuilder& self, LinearExpr target, std::vector<LinearExpr> exprs) {
        return self.AddLinMaxEquality(target, exprs);
      })
    .define_method(
      "add_division_equality",
      [](CpModelBuilder& self, IntVar target, IntVar numerator, IntVar denominator) {
        return self.AddDivisionEquality(target, numerator, denominator);
      })
    .define_method(
      "add_abs_equality",
      [](CpModelBuilder& self, IntVar target, IntVar var) {
        return self.AddAbsEquality(target, var);
      })
    .define_method(
      "add_modulo_equality",
      [](CpModelBuilder& self, IntVar target, IntVar var, IntVar mod) {
        return self.AddModuloEquality(target, var, mod);
      })
    .define_method(
      "add_product_equality",
      [](CpModelBuilder& self, IntVar target, std::vector<IntVar> vars) {
        return self.AddProductEquality(target, vars);
      })
    .define_method(
      "add_no_overlap",
      [](CpModelBuilder& self, std::vector<IntervalVar> vars) {
        return self.AddNoOverlap(vars);
      })
    .define_method(
      "maximize",
      [](CpModelBuilder& self, LinearExpr expr) {
        self.Maximize(expr);
      })
    .define_method(
      "minimize",
      [](CpModelBuilder& self, LinearExpr expr) {
        self.Minimize(expr);
      })
    .define_method(
      "scale_objective_by",
      [](CpModelBuilder& self, double scaling) {
        self.ScaleObjectiveBy(scaling);
      })
    .define_method(
      "add_hint",
      [](CpModelBuilder& self, IntVar var, int64_t value) {
        self.AddHint(var, value);
      })
    .define_method(
      "clear_hints",
      [](CpModelBuilder& self) {
        self.ClearHints();
      })
    .define_method(
      "add_assumption",
      [](CpModelBuilder& self, BoolVar lit) {
        self.AddAssumption(lit);
      })
    .define_method(
      "add_assumptions",
      [](CpModelBuilder& self, std::vector<BoolVar> literals) {
        self.AddAssumptions(literals);
      })
    .define_method(
      "clear_assumptions",
      [](CpModelBuilder& self) {
        self.ClearAssumptions();
      })
    .define_method(
      "to_s",
      [](CpModelBuilder& self) {
        std::string proto_string;
        google::protobuf::TextFormat::PrintToString(self.Proto(), &proto_string);
        return proto_string;
      });

  Rice::define_class_under<CpSolverResponse>(m, "CpSolverResponse")
    .define_method("objective_value", &CpSolverResponse::objective_value)
    .define_method("num_conflicts", &CpSolverResponse::num_conflicts)
    .define_method("num_branches", &CpSolverResponse::num_branches)
    .define_method("wall_time", &CpSolverResponse::wall_time)
    .define_method(
      "solution_integer_value",
      [](CpSolverResponse& self, IntVar& x) {
        LinearExpr expr(x);
        return SolutionIntegerValue(self, expr);
      })
    .define_method("solution_boolean_value", &SolutionBooleanValue)
    .define_method(
      "status",
      [](CpSolverResponse& self) {
        auto status = self.status();

        if (status == CpSolverStatus::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == CpSolverStatus::FEASIBLE) {
          return Symbol("feasible");
        } else if (status == CpSolverStatus::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == CpSolverStatus::MODEL_INVALID) {
          return Symbol("model_invalid");
        } else if (status == CpSolverStatus::UNKNOWN) {
          return Symbol("unknown");
        } else {
          throw std::runtime_error("Unknown solver status");
        }
      })
    .define_method(
      "sufficient_assumptions_for_infeasibility",
      [](CpSolverResponse& self) {
        auto a = Array();
        auto assumptions = self.sufficient_assumptions_for_infeasibility();
        for (const auto& v : assumptions) {
          a.push(v);
        }
        return a;
      });

  Rice::define_class_under(m, "CpSolver")
    .define_method(
      "_solve_with_observer",
      [](Object self, CpModelBuilder& model, SatParameters& parameters, Object callback, bool all_solutions) {
        Model m;

        if (all_solutions) {
          // set parameters for SearchForAllSolutions
          parameters.set_enumerate_all_solutions(true);
        }
        m.Add(NewSatParameters(parameters));

        m.Add(NewFeasibleSolutionObserver(
          [callback](const CpSolverResponse& r) {
            // TODO find a better way to do this
            callback.call("response=", r);
            callback.call("on_solution_callback");
          })
        );
        return SolveCpModel(model.Build(), &m);
      })
    .define_method(
      "_solve",
      [](Object self, CpModelBuilder& model, SatParameters& parameters) {
        Model m;
        m.Add(NewSatParameters(parameters));
        return SolveCpModel(model.Build(), &m);
      })
    .define_method(
      "_solution_integer_value",
      [](Object self, CpSolverResponse& response, IntVar& x) {
        return SolutionIntegerValue(response, x);
      })
    .define_method(
      "_solution_boolean_value",
      [](Object self, CpSolverResponse& response, BoolVar& x) {
        return SolutionBooleanValue(response, x);
      });
}
