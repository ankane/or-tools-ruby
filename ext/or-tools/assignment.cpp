#include <ortools/graph/assignment.h>

#include "ext.h"

using operations_research::SimpleLinearSumAssignment;

using Rice::Symbol;

void init_assignment(Rice::Module& m) {
  Rice::define_class_under<SimpleLinearSumAssignment>(m, "LinearSumAssignment")
    .define_constructor(Rice::Constructor<SimpleLinearSumAssignment>())
    .define_method("add_arc_with_cost", &SimpleLinearSumAssignment::AddArcWithCost)
    .define_method("num_nodes", &SimpleLinearSumAssignment::NumNodes)
    .define_method("num_arcs", &SimpleLinearSumAssignment::NumArcs)
    .define_method("left_node", &SimpleLinearSumAssignment::LeftNode)
    .define_method("right_node", &SimpleLinearSumAssignment::RightNode)
    .define_method("cost", &SimpleLinearSumAssignment::Cost)
    .define_method("optimal_cost", &SimpleLinearSumAssignment::OptimalCost)
    .define_method("right_mate", &SimpleLinearSumAssignment::RightMate)
    .define_method("assignment_cost", &SimpleLinearSumAssignment::AssignmentCost)
    .define_method(
      "solve",
      [](SimpleLinearSumAssignment& self) {
        auto status = self.Solve();

        if (status == SimpleLinearSumAssignment::Status::OPTIMAL) {
          return Symbol("optimal");
        } else if (status == SimpleLinearSumAssignment::Status::INFEASIBLE) {
          return Symbol("infeasible");
        } else if (status == SimpleLinearSumAssignment::Status::POSSIBLE_OVERFLOW) {
          return Symbol("possible_overflow");
        } else {
          throw std::runtime_error("Unknown status");
        }
      });
}
