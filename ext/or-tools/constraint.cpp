#include <ortools/sat/cp_model.h>

#include <rice/Array.hpp>
#include <rice/Constructor.hpp>
#include <rice/Module.hpp>

using operations_research::Domain;

using operations_research::sat::BoolVar;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::CpSolverStatus;
using operations_research::sat::NewFeasibleSolutionObserver;
using operations_research::sat::SatParameters;
using operations_research::sat::SolutionIntegerValue;

using Rice::Array;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

template<>
inline
operations_research::sat::LinearExpr from_ruby<operations_research::sat::LinearExpr>(Object x)
{
  operations_research::sat::LinearExpr expr;

  if (x.respond_to("to_i")) {
    expr = from_ruby<int64>(x.call("to_i"));
  } else if (x.respond_to("vars")) {
    Array vars = x.call("vars");
    for(auto const& var: vars) {
      auto cvar = (Array) var;
      // TODO clean up
      Object o = cvar[0];
      std::string type = ((String) o.call("class").call("name")).str();
      if (type == "ORTools::BoolVar") {
        expr.AddTerm(from_ruby<operations_research::sat::BoolVar>(cvar[0]), from_ruby<int64>(cvar[1]));
      } else if (type == "Integer") {
        expr.AddConstant(from_ruby<int64>(cvar[0]));
      } else {
        expr.AddTerm(from_ruby<operations_research::sat::IntVar>(cvar[0]), from_ruby<int64>(cvar[1]));
      }
    }
  } else {
    std::string type = ((String) x.call("class").call("name")).str();
    if (type == "ORTools::BoolVar") {
      expr = from_ruby<operations_research::sat::BoolVar>(x);
    } else {
      expr = from_ruby<operations_research::sat::IntVar>(x);
    }
  }

  return expr;
}

// need a wrapper class since absl::Span doesn't own
class IntVarSpan {
  std::vector<operations_research::sat::IntVar> vec;
  public:
    IntVarSpan(Object x) {
      Array a = Array(x);
      for (std::size_t i = 0; i < a.size(); ++i) {
        vec.push_back(from_ruby<operations_research::sat::IntVar>(a[i]));
      }
    }
    operator absl::Span<const operations_research::sat::IntVar>() {
      return absl::Span<const operations_research::sat::IntVar>(vec);
    }
};

template<>
inline
IntVarSpan from_ruby<IntVarSpan>(Object x)
{
  return IntVarSpan(x);
}

// need a wrapper class since absl::Span doesn't own
class IntervalVarSpan {
  std::vector<operations_research::sat::IntervalVar> vec;
  public:
    IntervalVarSpan(Object x) {
      Array a = Array(x);
      for (std::size_t i = 0; i < a.size(); ++i) {
        vec.push_back(from_ruby<operations_research::sat::IntervalVar>(a[i]));
      }
    }
    operator absl::Span<const operations_research::sat::IntervalVar>() {
      return absl::Span<const operations_research::sat::IntervalVar>(vec);
    }
};

template<>
inline
IntervalVarSpan from_ruby<IntervalVarSpan>(Object x)
{
  return IntervalVarSpan(x);
}

// need a wrapper class since absl::Span doesn't own
class BoolVarSpan {
  std::vector<operations_research::sat::BoolVar> vec;
  public:
    BoolVarSpan(Object x) {
      Array a = Array(x);
      for (std::size_t i = 0; i < a.size(); ++i) {
        vec.push_back(from_ruby<operations_research::sat::BoolVar>(a[i]));
      }
    }
    operator absl::Span<const operations_research::sat::BoolVar>() {
      return absl::Span<const operations_research::sat::BoolVar>(vec);
    }
};

template<>
inline
BoolVarSpan from_ruby<BoolVarSpan>(Object x)
{
  return BoolVarSpan(x);
}

void init_constraint(Rice::Module& m) {
  Rice::define_class_under<operations_research::sat::IntVar>(m, "SatIntVar")
    .define_method("name", &operations_research::sat::IntVar::Name);

  Rice::define_class_under<operations_research::sat::IntervalVar>(m, "SatIntervalVar")
    .define_method("name", &operations_research::sat::IntervalVar::Name);

  Rice::define_class_under<operations_research::sat::Constraint>(m, "SatConstraint");

  Rice::define_class_under<BoolVar>(m, "BoolVar")
    .define_method("name", &BoolVar::Name)
    .define_method("index", &BoolVar::index)
    .define_method("not", &BoolVar::Not)
    .define_method(
      "inspect",
      *[](BoolVar& self) {
        String name(self.Name());
        return "#<ORTools::BoolVar @name=" + name.inspect().str() + ">";
      });

  Rice::define_class_under<SatParameters>(m, "SatParameters")
    .define_constructor(Rice::Constructor<SatParameters>())
    .define_method("max_time_in_seconds=",
    *[](SatParameters& self, double value) {
      self.set_max_time_in_seconds(value);
    });

  Rice::define_class_under<CpModelBuilder>(m, "CpModel")
    .define_constructor(Rice::Constructor<CpModelBuilder>())
    .define_method(
      "new_int_var",
      *[](CpModelBuilder& self, int64 start, int64 end, std::string name) {
        const Domain domain(start, end);
        return self.NewIntVar(domain).WithName(name);
      })
    .define_method(
      "new_bool_var",
      *[](CpModelBuilder& self, std::string name) {
        return self.NewBoolVar().WithName(name);
      })
    .define_method(
      "new_interval_var",
      *[](CpModelBuilder& self, operations_research::sat::IntVar start, operations_research::sat::IntVar size, operations_research::sat::IntVar end, std::string name) {
        return self.NewIntervalVar(start, size, end).WithName(name);
      })
    .define_method(
      "add_equality",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddEquality(x, y);
      })
    .define_method(
      "add_not_equal",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddNotEqual(x, y);
      })
    .define_method(
      "add_greater_than",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddGreaterThan(x, y);
      })
    .define_method(
      "add_greater_or_equal",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddGreaterOrEqual(x, y);
      })
    .define_method(
      "add_less_than",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddLessThan(x, y);
      })
    .define_method(
      "add_less_or_equal",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr x, operations_research::sat::LinearExpr y) {
        self.AddLessOrEqual(x, y);
      })
    .define_method(
      "add_all_different",
      *[](CpModelBuilder& self, IntVarSpan vars) {
        self.AddAllDifferent(vars);
      })
    .define_method(
      "add_max_equality",
      *[](CpModelBuilder& self, operations_research::sat::IntVar target, IntVarSpan vars) {
        self.AddMaxEquality(target, vars);
      })
    .define_method(
      "add_no_overlap",
      *[](CpModelBuilder& self, IntervalVarSpan vars) {
        self.AddNoOverlap(vars);
      })
    .define_method(
      "add_bool_or",
      *[](CpModelBuilder& self, BoolVarSpan literals) {
        self.AddBoolOr(literals);
      })
    .define_method("add_implication", &CpModelBuilder::AddImplication)
    .define_method(
      "maximize",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr expr) {
        self.Maximize(expr);
      })
    .define_method(
      "minimize",
      *[](CpModelBuilder& self, operations_research::sat::LinearExpr expr) {
        self.Minimize(expr);
      });

  Rice::define_class_under(m, "CpSolver")
    .define_method(
      "_solve_with_observer",
      *[](Object self, CpModelBuilder& model, SatParameters& parameters, Object callback, bool all_solutions) {
        operations_research::sat::Model m;

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
      *[](Object self, CpModelBuilder& model, SatParameters& parameters) {
        operations_research::sat::Model m;
        m.Add(NewSatParameters(parameters));
        return SolveCpModel(model.Build(), &m);
      })
    .define_method(
      "_solution_integer_value",
      *[](Object self, CpSolverResponse& response, operations_research::sat::IntVar& x) {
        return SolutionIntegerValue(response, x);
      })
    .define_method(
      "_solution_boolean_value",
      *[](Object self, CpSolverResponse& response, operations_research::sat::BoolVar& x) {
        return SolutionBooleanValue(response, x);
      });

  Rice::define_class_under<CpSolverResponse>(m, "CpSolverResponse")
    .define_method("objective_value", &CpSolverResponse::objective_value)
    .define_method("num_conflicts", &CpSolverResponse::num_conflicts)
    .define_method("num_branches", &CpSolverResponse::num_branches)
    .define_method("wall_time", &CpSolverResponse::wall_time)
    .define_method(
      "solution_integer_value",
      *[](CpSolverResponse& self, operations_research::sat::IntVar& x) {
        operations_research::sat::LinearExpr expr(x);
        return SolutionIntegerValue(self, expr);
      })
    .define_method("solution_boolean_value", &operations_research::sat::SolutionBooleanValue)
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
        } else if (status == CpSolverStatus::UNKNOWN) {
          return Symbol("unknown");
        } else {
          throw std::runtime_error("Unknown solver status");
        }
      });
}
