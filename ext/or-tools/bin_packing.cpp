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
      auto s = Symbol(x).str();
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
       [](KnapsackSolver& self, std::vector<int64_t> values, std::vector<std::vector<int64_t>> weights, std::vector<int64_t> capacities) {
        self.Init(values, weights, capacities);
      });
}
