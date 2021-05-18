#include <ortools/algorithms/knapsack_solver.h>

#include "ext.h"

using operations_research::KnapsackSolver;

using Rice::Array;
using Rice::Object;
using Rice::Symbol;

namespace Rice::detail
{
  template<>
  struct Type<KnapsackSolver::SolverType>
  {
    static bool verify()
    {
      return true;
    }
  };

  template<>
  class From_Ruby<KnapsackSolver::SolverType>
  {
  public:
    KnapsackSolver::SolverType convert(VALUE x)
    {
      Object obj(x);
      std::string s = Symbol(obj).str();
      if (s == "branch_and_bound") {
        return KnapsackSolver::KNAPSACK_MULTIDIMENSION_BRANCH_AND_BOUND_SOLVER;
      } else {
        throw std::runtime_error("Unknown solver type: " + s);
      }
    }
  };
}

void init_bin_packing(Rice::Module& m) {
  Rice::define_class_under<KnapsackSolver>(m, "KnapsackSolver")
    .define_constructor(Rice::Constructor<KnapsackSolver, KnapsackSolver::SolverType, std::string>())
    .define_method("_solve", &KnapsackSolver::Solve)
    .define_method("best_solution_contains?", &KnapsackSolver::BestSolutionContains)
    .define_method(
      "init",
      [](KnapsackSolver& self, Array rb_values, Array rb_weights, Array rb_capacities) {
        std::vector<int64_t> values;
        for (std::size_t i = 0; i < rb_values.size(); ++i) {
          values.push_back(Rice::detail::From_Ruby<int64_t>().convert(rb_values[i].value()));
        }

        std::vector<std::vector<int64_t>> weights;
        for (std::size_t i = 0; i < rb_weights.size(); ++i) {
          Array rb_w = Array(rb_weights[i]);
          std::vector<int64_t> w;
          for (std::size_t j = 0; j < rb_w.size(); ++j) {
            w.push_back(Rice::detail::From_Ruby<int64_t>().convert(rb_w[j].value()));
          }
          weights.push_back(w);
        }

        std::vector<int64_t> capacities;
        for (std::size_t i = 0; i < rb_capacities.size(); ++i) {
          capacities.push_back(Rice::detail::From_Ruby<int64_t>().convert(rb_capacities[i].value()));
        }

        self.Init(values, weights, capacities);
      });
}
