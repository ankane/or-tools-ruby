#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <google/protobuf/text_format.h>
#include <ortools/sat/cp_model.h>
#include <rice/rice.hpp>
#include <rice/stl.hpp>
#include <ruby/thread.h>

using operations_research::Domain;
using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::TableConstraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpModelProto;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::CpSolverStatus;
using operations_research::sat::LinearExpr;
using operations_research::sat::IntVar;
using operations_research::sat::IntervalVar;
using operations_research::sat::Model;
using operations_research::sat::NewFeasibleSolutionObserver;
using operations_research::sat::SolveCpModel;
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

// Thread-safe queue that lets OR-Tools worker threads enqueue responses while a Ruby-owned
// thread drains the queue and invokes the Ruby callback after reacquiring the GVL.
struct CallbackQueue {
  std::mutex mutex;
  std::condition_variable cv;
  std::deque<CpSolverResponse> responses;
  bool solver_finished = false;
  bool has_final_response = false;
  CpSolverResponse final_response;
};

struct WaitForEventArgs {
  CallbackQueue* queue;
  bool has_response = false;
  CpSolverResponse response;
};

static void* wait_for_event_without_gvl(void* ptr) {
  auto* args = static_cast<WaitForEventArgs*>(ptr);
  std::unique_lock<std::mutex> lock(args->queue->mutex);
  args->queue->cv.wait(lock, [args]() {
    return args->queue->solver_finished || !args->queue->responses.empty();
  });

  if (!args->queue->responses.empty()) {
    args->response = args->queue->responses.front();
    args->queue->responses.pop_front();
    args->has_response = true;
  } else {
    args->has_response = false;
  }

  return nullptr;
}

static CpSolverResponse solve_cp_model_without_gvl(const CpModelProto* proto, Model* model) {
  return SolveCpModel(*proto, model);
}

namespace Rice::detail {
  template<>
  struct Type<LinearExpr> {
    static bool verify() { return true; }
  };

  template<>
  class From_Ruby<LinearExpr> {
  public:
    From_Ruby() = default;

    explicit From_Ruby(Arg* arg) : arg_(arg) { }

    Convertible is_convertible(VALUE value) { return Convertible::Cast; }

    LinearExpr convert(VALUE v) {
      LinearExpr expr;

      Rice::Object utils = Rice::define_module("ORTools").const_get("Utils");
      Rice::Hash coeffs = utils.call("index_expression", Object(v));

      for (const auto& entry : coeffs) {
        Object var = entry.key;
        auto coeff = From_Ruby<int64_t>().convert(entry.value.value());

        if (var.is_nil()) {
          expr += coeff;
        } else if (var.is_a(rb_cBoolVar)) {
          expr += From_Ruby<BoolVar>().convert(var.value()) * coeff;
        } else {
          expr += From_Ruby<IntVar>().convert(var.value()) * coeff;
        }
      }

      return expr;
    }

  private:
    Arg* arg_ = nullptr;
  };
} // namespace Rice::detail

void init_constraint(Rice::Module& m) {
  Rice::define_class_under<Domain>(m, "Domain")
    .define_constructor(Rice::Constructor<Domain, int64_t, int64_t>())
    .define_singleton_function("from_values", &Domain::FromValues)
    .define_method("min", &Domain::Min)
    .define_method("max", &Domain::Max);

  rb_cSatIntVar = Rice::define_class_under<IntVar>(m, "SatIntVar")
    .define_method("name", &IntVar::Name)
    .define_method("domain", &IntVar::Domain);

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
          auto a = Array(literal);
          std::vector<BoolVar> vec;
          vec.reserve(a.size());
          for (const Object v : a) {
            if (v.is_a(rb_cSatIntVar)) {
              vec.push_back(Rice::detail::From_Ruby<IntVar>().convert(v.value()).ToBoolVar());
            } else {
              vec.push_back(Rice::detail::From_Ruby<BoolVar>().convert(v.value()));
            }
          }
          return self.OnlyEnforceIf(vec);
        } else {
          return self.OnlyEnforceIf(Rice::detail::From_Ruby<BoolVar>().convert(literal));
        }
      });

  Rice::define_class_under<TableConstraint, Constraint>(m, "SatTableConstraint")
    .define_method(
      "add_tuple",
      [](TableConstraint& self, std::vector<int64_t> tuple) {
        self.AddTuple(tuple);
      });

  rb_cBoolVar = Rice::define_class_under<BoolVar>(m, "SatBoolVar")
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
    .define_method(
      "max_time_in_seconds=",
      [](SatParameters& self, double value) {
        self.set_max_time_in_seconds(value);
      })
    .define_method(
      "enumerate_all_solutions=",
      [](SatParameters& self, bool value) {
        self.set_enumerate_all_solutions(value);
      })
    .define_method(
      "enumerate_all_solutions",
      [](SatParameters& self) {
        return self.enumerate_all_solutions();
       })
    .define_method("num_workers=",
      [](SatParameters& self, int32_t value){
        self.set_num_workers(value);
      })
    .define_method("cp_model_presolve=",
      [](SatParameters& self, bool value) {
        self.set_cp_model_presolve(value);
      })
    .define_method("random_seed",
      [](SatParameters& self) {
        return self.random_seed();
      })
    .define_method("random_seed=",
      [](SatParameters& self, int32_t value) {
        self.set_random_seed(value);
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
    .define_method(
      "add_linear_constraint",
      [](CpModelBuilder& self, LinearExpr expr, int64_t lb, int64_t ub) {
        return self.AddLinearConstraint(expr, Domain(lb, ub));
      })
    .define_method(
      "add_linear_expression_in_domain",
      [](CpModelBuilder& self, LinearExpr expr, Domain domain) {
        return self.AddLinearConstraint(expr, domain);
      })
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
      "add_allowed_assignments",
      [](CpModelBuilder& self, std::vector<LinearExpr> expressions) {
        return self.AddAllowedAssignments(expressions);
      })
    .define_method(
      "add_forbidden_assignments",
      [](CpModelBuilder& self, std::vector<LinearExpr> expressions) {
        return self.AddForbiddenAssignments(expressions);
      })
    .define_method(
      "add_inverse_constraint",
      [](CpModelBuilder& self, std::vector<IntVar> variables, std::vector<IntVar> inverse_variables) {
        return self.AddInverseConstraint(variables, inverse_variables);
      })
    .define_method(
      "add_min_equality",
      [](CpModelBuilder& self, LinearExpr target, std::vector<LinearExpr> vars) {
        return self.AddMinEquality(target, vars);
      })
    .define_method(
      "add_max_equality",
      [](CpModelBuilder& self, LinearExpr target, std::vector<LinearExpr> vars) {
        return self.AddMaxEquality(target, vars);
      })
    .define_method(
      "add_division_equality",
      [](CpModelBuilder& self, LinearExpr target, LinearExpr numerator, LinearExpr denominator) {
        return self.AddDivisionEquality(target, numerator, denominator);
      })
    .define_method(
      "add_abs_equality",
      [](CpModelBuilder& self, LinearExpr target, LinearExpr var) {
        return self.AddAbsEquality(target, var);
      })
    .define_method(
      "add_modulo_equality",
      [](CpModelBuilder& self, LinearExpr target, LinearExpr var, LinearExpr mod) {
        return self.AddModuloEquality(target, var, mod);
      })
    .define_method(
      "add_multiplication_equality",
      [](CpModelBuilder& self, LinearExpr target, std::vector<LinearExpr> vars) {
        return self.AddMultiplicationEquality(target, vars);
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
      "add_hint",
      [](CpModelBuilder& self, Object var, Object value) {
        if (var.is_a(rb_cBoolVar)) {
          self.AddHint(
            Rice::detail::From_Ruby<BoolVar>().convert(var.value()),
            Rice::detail::From_Ruby<bool>().convert(value.value())
          );
        } else {
          self.AddHint(
            Rice::detail::From_Ruby<IntVar>().convert(var.value()),
            Rice::detail::From_Ruby<int64_t>().convert(value.value())
          );
        }
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
      "export_to_file",
      [](CpModelBuilder& self, const std::string& filename) {
        return self.ExportToFile(filename);
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
      "solution_info",
      [](CpSolverResponse& self) {
        return self.solution_info();
      })
    .define_method(
      "sufficient_assumptions_for_infeasibility",
      [](CpSolverResponse& self) {
        auto a = Array();
        auto assumptions = self.sufficient_assumptions_for_infeasibility();
        for (const auto& v : assumptions) {
          a.push(v, false);
        }
        return a;
      });

  Rice::define_class_under(m, "CpSolver")
    .define_method(
      "_solve",
      [](Object self, CpModelBuilder& model, SatParameters& parameters, Object callback) {
        Model solver_model;

        bool has_callback = !callback.is_nil();
        VALUE rb_cb = Qnil;
        std::shared_ptr<CallbackQueue> callback_queue;

        if (has_callback) {
          rb_cb = callback.value();
          rb_gc_register_address(&rb_cb);

          callback_queue = std::make_shared<CallbackQueue>();

          solver_model.Add(NewFeasibleSolutionObserver(
            [callback_queue](const CpSolverResponse& r) {
              std::lock_guard<std::mutex> lock(callback_queue->mutex);
              callback_queue->responses.push_back(r);
              callback_queue->cv.notify_one();
            })
          );
        }

        solver_model.Add(NewSatParameters(parameters));
        const CpModelProto proto = model.Build();

        if (!has_callback) {
          return Rice::detail::no_gvl(
            &solve_cp_model_without_gvl,
            &proto,
            &solver_model);
        }

        std::thread solver_thread(
          [&proto, &solver_model, callback_queue]() {
            auto response = solve_cp_model_without_gvl(&proto, &solver_model);
            {
              std::lock_guard<std::mutex> lock(callback_queue->mutex);
              callback_queue->final_response = response;
              callback_queue->has_final_response = true;
              callback_queue->solver_finished = true;
            }
            callback_queue->cv.notify_all();
          });

        CpSolverResponse final_response;

        try {
          Rice::Object rb_callback(rb_cb);

          while (true) {
            WaitForEventArgs wait_args{callback_queue.get()};
            rb_thread_call_without_gvl(
              wait_for_event_without_gvl,
              &wait_args,
              RUBY_UBF_IO,
              nullptr);

            if (wait_args.has_response) {
              rb_callback.call("response=", wait_args.response);
              rb_callback.call("on_solution_callback");
            }

            bool done = false;
            {
              std::lock_guard<std::mutex> lock(callback_queue->mutex);
              done = callback_queue->solver_finished && callback_queue->responses.empty();
            }

            if (done && !wait_args.has_response) {
              break;
            }
          }
        } catch (...) {
          solver_thread.join();
          rb_gc_unregister_address(&rb_cb);
          throw;
        }

        solver_thread.join();

        {
          std::lock_guard<std::mutex> lock(callback_queue->mutex);
          if (callback_queue->has_final_response) {
            final_response = callback_queue->final_response;
          }
        }

        rb_gc_unregister_address(&rb_cb);
        return final_response;
      })
    .define_method(
      "_solution_integer_value",
      [](Object self, const CpSolverResponse& response, IntVar x) {
        return SolutionIntegerValue(response, x);
      })
    .define_method(
      "_solution_boolean_value",
      [](Object self, const CpSolverResponse& response, BoolVar x) {
        return SolutionBooleanValue(response, x);
      });
}
