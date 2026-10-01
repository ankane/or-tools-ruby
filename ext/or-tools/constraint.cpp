#include <atomic>
#include <chrono>
#include <optional>
#include <string>
#include <vector>

#include <google/protobuf/text_format.h>
#include <ortools/sat/cp_model.h>
#include <rice/rice.hpp>
#include <rice/stl.hpp>

#include "channel.hpp"

using operations_research::Domain;
using operations_research::sat::BoolVar;
using operations_research::sat::Constraint;
using operations_research::sat::CpModelBuilder;
using operations_research::sat::CpSolverResponse;
using operations_research::sat::CpSolverStatus;
using operations_research::sat::IntervalVar;
using operations_research::sat::IntVar;
using operations_research::sat::LinearExpr;
using operations_research::sat::Model;
using operations_research::sat::NewFeasibleSolutionObserver;
using operations_research::sat::SatParameters;
using operations_research::sat::SolutionBooleanValue;
using operations_research::sat::SolutionIntegerValue;
using operations_research::sat::TableConstraint;

using Rice::Array;
using Rice::Class;
using Rice::Hash;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

Class rb_cBoolVar;
Class rb_cSatIntVar;

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

    double is_convertible(VALUE value) { return Convertible::Exact; }

    LinearExpr convert(VALUE v) {
      LinearExpr expr;

      Object utils = Rice::define_module("ORTools").const_get("Utils");
      Hash coeffs = utils.call("index_expression", Object(v));

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
          for (const auto& v : a) {
            if (Object(v).is_a(rb_cSatIntVar)) {
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
    .define_method("absolute_gap_limit", &SatParameters::absolute_gap_limit)
    .define_method("absolute_gap_limit=", &SatParameters::set_absolute_gap_limit)
    .define_method("add_cg_cuts", &SatParameters::add_cg_cuts)
    .define_method("add_cg_cuts=", &SatParameters::set_add_cg_cuts)
    .define_method("add_clique_cuts", &SatParameters::add_clique_cuts)
    .define_method("add_clique_cuts=", &SatParameters::set_add_clique_cuts)
    .define_method("add_lin_max_cuts", &SatParameters::add_lin_max_cuts)
    .define_method("add_lin_max_cuts=", &SatParameters::set_add_lin_max_cuts)
    .define_method("add_lp_constraints_lazily", &SatParameters::add_lp_constraints_lazily)
    .define_method("add_lp_constraints_lazily=", &SatParameters::set_add_lp_constraints_lazily)
    .define_method("add_mir_cuts", &SatParameters::add_mir_cuts)
    .define_method("add_mir_cuts=", &SatParameters::set_add_mir_cuts)
    .define_method("add_objective_cut", &SatParameters::add_objective_cut)
    .define_method("add_objective_cut=", &SatParameters::set_add_objective_cut)
    .define_method("add_rlt_cuts", &SatParameters::add_rlt_cuts)
    .define_method("add_rlt_cuts=", &SatParameters::set_add_rlt_cuts)
    .define_method("add_zero_half_cuts", &SatParameters::add_zero_half_cuts)
    .define_method("add_zero_half_cuts=", &SatParameters::set_add_zero_half_cuts)
    .define_method("also_bump_variables_in_conflict_reasons", &SatParameters::also_bump_variables_in_conflict_reasons)
    .define_method("also_bump_variables_in_conflict_reasons=", &SatParameters::set_also_bump_variables_in_conflict_reasons)
    .define_method("alternative_pool_size", &SatParameters::alternative_pool_size)
    .define_method("alternative_pool_size=", &SatParameters::set_alternative_pool_size)
    .define_method("at_most_one_max_expansion_size", &SatParameters::at_most_one_max_expansion_size)
    .define_method("at_most_one_max_expansion_size=", &SatParameters::set_at_most_one_max_expansion_size)
    .define_method("auto_detect_greater_than_at_least_one_of", &SatParameters::auto_detect_greater_than_at_least_one_of)
    .define_method("auto_detect_greater_than_at_least_one_of=", &SatParameters::set_auto_detect_greater_than_at_least_one_of)
    .define_method("binary_search_num_conflicts", &SatParameters::binary_search_num_conflicts)
    .define_method("binary_search_num_conflicts=", &SatParameters::set_binary_search_num_conflicts)
    .define_method("blocking_restart_multiplier", &SatParameters::blocking_restart_multiplier)
    .define_method("blocking_restart_multiplier=", &SatParameters::set_blocking_restart_multiplier)
    .define_method("blocking_restart_window_size", &SatParameters::blocking_restart_window_size)
    .define_method("blocking_restart_window_size=", &SatParameters::set_blocking_restart_window_size)
    .define_method("boolean_encoding_level", &SatParameters::boolean_encoding_level)
    .define_method("boolean_encoding_level=", &SatParameters::set_boolean_encoding_level)
    .define_method("catch_sigint_signal", &SatParameters::catch_sigint_signal)
    .define_method("catch_sigint_signal=", &SatParameters::set_catch_sigint_signal)
    .define_method("check_drat_proof", &SatParameters::check_drat_proof)
    .define_method("check_drat_proof=", &SatParameters::set_check_drat_proof)
    .define_method("check_lrat_proof", &SatParameters::check_lrat_proof)
    .define_method("check_lrat_proof=", &SatParameters::set_check_lrat_proof)
    .define_method("check_merged_lrat_proof", &SatParameters::check_merged_lrat_proof)
    .define_method("check_merged_lrat_proof=", &SatParameters::set_check_merged_lrat_proof)
    .define_method("chronological_backtrack_min_conflicts", &SatParameters::chronological_backtrack_min_conflicts)
    .define_method("chronological_backtrack_min_conflicts=", &SatParameters::set_chronological_backtrack_min_conflicts)
    .define_method("clause_activity_decay", &SatParameters::clause_activity_decay)
    .define_method("clause_activity_decay=", &SatParameters::set_clause_activity_decay)
    .define_method("clause_cleanup_lbd_bound", &SatParameters::clause_cleanup_lbd_bound)
    .define_method("clause_cleanup_lbd_bound=", &SatParameters::set_clause_cleanup_lbd_bound)
    .define_method("clause_cleanup_lbd_tier1", &SatParameters::clause_cleanup_lbd_tier1)
    .define_method("clause_cleanup_lbd_tier1=", &SatParameters::set_clause_cleanup_lbd_tier1)
    .define_method("clause_cleanup_lbd_tier2", &SatParameters::clause_cleanup_lbd_tier2)
    .define_method("clause_cleanup_lbd_tier2=", &SatParameters::set_clause_cleanup_lbd_tier2)
    .define_method("clause_cleanup_period", &SatParameters::clause_cleanup_period)
    .define_method("clause_cleanup_period=", &SatParameters::set_clause_cleanup_period)
    .define_method("clause_cleanup_period_increment", &SatParameters::clause_cleanup_period_increment)
    .define_method("clause_cleanup_period_increment=", &SatParameters::set_clause_cleanup_period_increment)
    .define_method("clause_cleanup_ratio", &SatParameters::clause_cleanup_ratio)
    .define_method("clause_cleanup_ratio=", &SatParameters::set_clause_cleanup_ratio)
    .define_method("clause_cleanup_target", &SatParameters::clause_cleanup_target)
    .define_method("clause_cleanup_target=", &SatParameters::set_clause_cleanup_target)
    .define_method("convert_intervals", &SatParameters::convert_intervals)
    .define_method("convert_intervals=", &SatParameters::set_convert_intervals)
    .define_method("core_minimization_level", &SatParameters::core_minimization_level)
    .define_method("core_minimization_level=", &SatParameters::set_core_minimization_level)
    .define_method("count_assumption_levels_in_lbd", &SatParameters::count_assumption_levels_in_lbd)
    .define_method("count_assumption_levels_in_lbd=", &SatParameters::set_count_assumption_levels_in_lbd)
    .define_method("cover_optimization", &SatParameters::cover_optimization)
    .define_method("cover_optimization=", &SatParameters::set_cover_optimization)
    .define_method("cp_model_presolve", &SatParameters::cp_model_presolve)
    .define_method("cp_model_presolve=", &SatParameters::set_cp_model_presolve)
    .define_method("cp_model_probing_level", &SatParameters::cp_model_probing_level)
    .define_method("cp_model_probing_level=", &SatParameters::set_cp_model_probing_level)
    .define_method("cp_model_use_sat_presolve", &SatParameters::cp_model_use_sat_presolve)
    .define_method("cp_model_use_sat_presolve=", &SatParameters::set_cp_model_use_sat_presolve)
    .define_method("create_1uip_boolean_during_icr", &SatParameters::create_1uip_boolean_during_icr)
    .define_method("create_1uip_boolean_during_icr=", &SatParameters::set_create_1uip_boolean_during_icr)
    .define_method("cut_active_count_decay", &SatParameters::cut_active_count_decay)
    .define_method("cut_active_count_decay=", &SatParameters::set_cut_active_count_decay)
    .define_method("cut_cleanup_target", &SatParameters::cut_cleanup_target)
    .define_method("cut_cleanup_target=", &SatParameters::set_cut_cleanup_target)
    .define_method("cut_level", &SatParameters::cut_level)
    .define_method("cut_level=", &SatParameters::set_cut_level)
    .define_method("cut_max_active_count_value", &SatParameters::cut_max_active_count_value)
    .define_method("cut_max_active_count_value=", &SatParameters::set_cut_max_active_count_value)
    .define_method("debug_crash_if_lrat_check_fails", &SatParameters::debug_crash_if_lrat_check_fails)
    .define_method("debug_crash_if_lrat_check_fails=", &SatParameters::set_debug_crash_if_lrat_check_fails)
    .define_method("debug_crash_if_presolve_breaks_hint", &SatParameters::debug_crash_if_presolve_breaks_hint)
    .define_method("debug_crash_if_presolve_breaks_hint=", &SatParameters::set_debug_crash_if_presolve_breaks_hint)
    .define_method("debug_crash_on_bad_hint", &SatParameters::debug_crash_on_bad_hint)
    .define_method("debug_crash_on_bad_hint=", &SatParameters::set_debug_crash_on_bad_hint)
    .define_method("debug_max_num_presolve_operations", &SatParameters::debug_max_num_presolve_operations)
    .define_method("debug_max_num_presolve_operations=", &SatParameters::set_debug_max_num_presolve_operations)
    .define_method("debug_postsolve_with_full_solver", &SatParameters::debug_postsolve_with_full_solver)
    .define_method("debug_postsolve_with_full_solver=", &SatParameters::set_debug_postsolve_with_full_solver)
    .define_method("decision_subsumption_during_conflict_analysis", &SatParameters::decision_subsumption_during_conflict_analysis)
    .define_method("decision_subsumption_during_conflict_analysis=", &SatParameters::set_decision_subsumption_during_conflict_analysis)
    .define_method("default_restart_algorithms", &SatParameters::default_restart_algorithms)
    // .define_method("default_restart_algorithms=", &SatParameters::set_default_restart_algorithms)
    .define_method("detect_linearized_product", &SatParameters::detect_linearized_product)
    .define_method("detect_linearized_product=", &SatParameters::set_detect_linearized_product)
    .define_method("detect_table_with_cost", &SatParameters::detect_table_with_cost)
    .define_method("detect_table_with_cost=", &SatParameters::set_detect_table_with_cost)
    .define_method("disable_constraint_expansion", &SatParameters::disable_constraint_expansion)
    .define_method("disable_constraint_expansion=", &SatParameters::set_disable_constraint_expansion)
    .define_method("diversify_lns_params", &SatParameters::diversify_lns_params)
    .define_method("diversify_lns_params=", &SatParameters::set_diversify_lns_params)
    .define_method("eagerly_subsume_last_n_conflicts", &SatParameters::eagerly_subsume_last_n_conflicts)
    .define_method("eagerly_subsume_last_n_conflicts=", &SatParameters::set_eagerly_subsume_last_n_conflicts)
    .define_method("encode_complex_linear_constraint_with_integer", &SatParameters::encode_complex_linear_constraint_with_integer)
    .define_method("encode_complex_linear_constraint_with_integer=", &SatParameters::set_encode_complex_linear_constraint_with_integer)
    .define_method("encode_cumulative_as_reservoir", &SatParameters::encode_cumulative_as_reservoir)
    .define_method("encode_cumulative_as_reservoir=", &SatParameters::set_encode_cumulative_as_reservoir)
    .define_method("enumerate_all_solutions", &SatParameters::enumerate_all_solutions)
    .define_method("enumerate_all_solutions=", &SatParameters::set_enumerate_all_solutions)
    .define_method("expand_alldiff_constraints", &SatParameters::expand_alldiff_constraints)
    .define_method("expand_alldiff_constraints=", &SatParameters::set_expand_alldiff_constraints)
    .define_method("expand_reservoir_constraints", &SatParameters::expand_reservoir_constraints)
    .define_method("expand_reservoir_constraints=", &SatParameters::set_expand_reservoir_constraints)
    .define_method("expand_reservoir_using_circuit", &SatParameters::expand_reservoir_using_circuit)
    .define_method("expand_reservoir_using_circuit=", &SatParameters::set_expand_reservoir_using_circuit)
    .define_method("exploit_all_lp_solution", &SatParameters::exploit_all_lp_solution)
    .define_method("exploit_all_lp_solution=", &SatParameters::set_exploit_all_lp_solution)
    .define_method("exploit_all_precedences", &SatParameters::exploit_all_precedences)
    .define_method("exploit_all_precedences=", &SatParameters::set_exploit_all_precedences)
    .define_method("exploit_best_solution", &SatParameters::exploit_best_solution)
    .define_method("exploit_best_solution=", &SatParameters::set_exploit_best_solution)
    .define_method("exploit_integer_lp_solution", &SatParameters::exploit_integer_lp_solution)
    .define_method("exploit_integer_lp_solution=", &SatParameters::set_exploit_integer_lp_solution)
    .define_method("exploit_objective", &SatParameters::exploit_objective)
    .define_method("exploit_objective=", &SatParameters::set_exploit_objective)
    .define_method("exploit_relaxation_solution", &SatParameters::exploit_relaxation_solution)
    .define_method("exploit_relaxation_solution=", &SatParameters::set_exploit_relaxation_solution)
    .define_method("extra_subsumption_during_conflict_analysis", &SatParameters::extra_subsumption_during_conflict_analysis)
    .define_method("extra_subsumption_during_conflict_analysis=", &SatParameters::set_extra_subsumption_during_conflict_analysis)
    .define_method("feasibility_jump_batch_dtime", &SatParameters::feasibility_jump_batch_dtime)
    .define_method("feasibility_jump_batch_dtime=", &SatParameters::set_feasibility_jump_batch_dtime)
    .define_method("feasibility_jump_decay", &SatParameters::feasibility_jump_decay)
    .define_method("feasibility_jump_decay=", &SatParameters::set_feasibility_jump_decay)
    .define_method("feasibility_jump_enable_restarts", &SatParameters::feasibility_jump_enable_restarts)
    .define_method("feasibility_jump_enable_restarts=", &SatParameters::set_feasibility_jump_enable_restarts)
    .define_method("feasibility_jump_linearization_level", &SatParameters::feasibility_jump_linearization_level)
    .define_method("feasibility_jump_linearization_level=", &SatParameters::set_feasibility_jump_linearization_level)
    .define_method("feasibility_jump_max_expanded_constraint_size", &SatParameters::feasibility_jump_max_expanded_constraint_size)
    .define_method("feasibility_jump_max_expanded_constraint_size=", &SatParameters::set_feasibility_jump_max_expanded_constraint_size)
    .define_method("feasibility_jump_restart_factor", &SatParameters::feasibility_jump_restart_factor)
    .define_method("feasibility_jump_restart_factor=", &SatParameters::set_feasibility_jump_restart_factor)
    .define_method("feasibility_jump_var_perburbation_range_ratio", &SatParameters::feasibility_jump_var_perburbation_range_ratio)
    .define_method("feasibility_jump_var_perburbation_range_ratio=", &SatParameters::set_feasibility_jump_var_perburbation_range_ratio)
    .define_method("feasibility_jump_var_randomization_probability", &SatParameters::feasibility_jump_var_randomization_probability)
    .define_method("feasibility_jump_var_randomization_probability=", &SatParameters::set_feasibility_jump_var_randomization_probability)
    .define_method("fill_additional_solutions_in_response", &SatParameters::fill_additional_solutions_in_response)
    .define_method("fill_additional_solutions_in_response=", &SatParameters::set_fill_additional_solutions_in_response)
    .define_method("fill_tightened_domains_in_response", &SatParameters::fill_tightened_domains_in_response)
    .define_method("fill_tightened_domains_in_response=", &SatParameters::set_fill_tightened_domains_in_response)
    .define_method("filter_sat_postsolve_clauses", &SatParameters::filter_sat_postsolve_clauses)
    .define_method("filter_sat_postsolve_clauses=", &SatParameters::set_filter_sat_postsolve_clauses)
    .define_method("find_big_linear_overlap", &SatParameters::find_big_linear_overlap)
    .define_method("find_big_linear_overlap=", &SatParameters::set_find_big_linear_overlap)
    .define_method("find_clauses_that_are_exactly_one", &SatParameters::find_clauses_that_are_exactly_one)
    .define_method("find_clauses_that_are_exactly_one=", &SatParameters::set_find_clauses_that_are_exactly_one)
    .define_method("find_multiple_cores", &SatParameters::find_multiple_cores)
    .define_method("find_multiple_cores=", &SatParameters::set_find_multiple_cores)
    .define_method("fix_variables_to_their_hinted_value", &SatParameters::fix_variables_to_their_hinted_value)
    .define_method("fix_variables_to_their_hinted_value=", &SatParameters::set_fix_variables_to_their_hinted_value)
    .define_method("glucose_decay_increment", &SatParameters::glucose_decay_increment)
    .define_method("glucose_decay_increment=", &SatParameters::set_glucose_decay_increment)
    .define_method("glucose_decay_increment_period", &SatParameters::glucose_decay_increment_period)
    .define_method("glucose_decay_increment_period=", &SatParameters::set_glucose_decay_increment_period)
    .define_method("glucose_max_decay", &SatParameters::glucose_max_decay)
    .define_method("glucose_max_decay=", &SatParameters::set_glucose_max_decay)
    .define_method("hint_conflict_limit", &SatParameters::hint_conflict_limit)
    .define_method("hint_conflict_limit=", &SatParameters::set_hint_conflict_limit)
    .define_method("ignore_names", &SatParameters::ignore_names)
    .define_method("ignore_names=", &SatParameters::set_ignore_names)
    .define_method("infer_all_diffs", &SatParameters::infer_all_diffs)
    .define_method("infer_all_diffs=", &SatParameters::set_infer_all_diffs)
    .define_method("initial_variables_activity", &SatParameters::initial_variables_activity)
    .define_method("initial_variables_activity=", &SatParameters::set_initial_variables_activity)
    .define_method("inprocessing_dtime_ratio", &SatParameters::inprocessing_dtime_ratio)
    .define_method("inprocessing_dtime_ratio=", &SatParameters::set_inprocessing_dtime_ratio)
    .define_method("inprocessing_minimization_dtime", &SatParameters::inprocessing_minimization_dtime)
    .define_method("inprocessing_minimization_dtime=", &SatParameters::set_inprocessing_minimization_dtime)
    .define_method("inprocessing_minimization_use_all_orderings", &SatParameters::inprocessing_minimization_use_all_orderings)
    .define_method("inprocessing_minimization_use_all_orderings=", &SatParameters::set_inprocessing_minimization_use_all_orderings)
    .define_method("inprocessing_minimization_use_conflict_analysis", &SatParameters::inprocessing_minimization_use_conflict_analysis)
    .define_method("inprocessing_minimization_use_conflict_analysis=", &SatParameters::set_inprocessing_minimization_use_conflict_analysis)
    .define_method("inprocessing_probing_dtime", &SatParameters::inprocessing_probing_dtime)
    .define_method("inprocessing_probing_dtime=", &SatParameters::set_inprocessing_probing_dtime)
    .define_method("inprocessing_use_congruence_closure", &SatParameters::inprocessing_use_congruence_closure)
    .define_method("inprocessing_use_congruence_closure=", &SatParameters::set_inprocessing_use_congruence_closure)
    .define_method("inprocessing_use_sat_sweeping", &SatParameters::inprocessing_use_sat_sweeping)
    .define_method("inprocessing_use_sat_sweeping=", &SatParameters::set_inprocessing_use_sat_sweeping)
    .define_method("instantiate_all_variables", &SatParameters::instantiate_all_variables)
    .define_method("instantiate_all_variables=", &SatParameters::set_instantiate_all_variables)
    .define_method("interleave_batch_size", &SatParameters::interleave_batch_size)
    .define_method("interleave_batch_size=", &SatParameters::set_interleave_batch_size)
    .define_method("interleave_search", &SatParameters::interleave_search)
    .define_method("interleave_search=", &SatParameters::set_interleave_search)
    .define_method("keep_all_feasible_solutions_in_presolve", &SatParameters::keep_all_feasible_solutions_in_presolve)
    .define_method("keep_all_feasible_solutions_in_presolve=", &SatParameters::set_keep_all_feasible_solutions_in_presolve)
    .define_method("keep_symmetry_in_presolve", &SatParameters::keep_symmetry_in_presolve)
    .define_method("keep_symmetry_in_presolve=", &SatParameters::set_keep_symmetry_in_presolve)
    .define_method("lb_relax_num_workers_threshold", &SatParameters::lb_relax_num_workers_threshold)
    .define_method("lb_relax_num_workers_threshold=", &SatParameters::set_lb_relax_num_workers_threshold)
    .define_method("linear_split_size", &SatParameters::linear_split_size)
    .define_method("linear_split_size=", &SatParameters::set_linear_split_size)
    .define_method("linearization_level", &SatParameters::linearization_level)
    .define_method("linearization_level=", &SatParameters::set_linearization_level)
    .define_method("lns_initial_deterministic_limit", &SatParameters::lns_initial_deterministic_limit)
    .define_method("lns_initial_deterministic_limit=", &SatParameters::set_lns_initial_deterministic_limit)
    .define_method("lns_initial_difficulty", &SatParameters::lns_initial_difficulty)
    .define_method("lns_initial_difficulty=", &SatParameters::set_lns_initial_difficulty)
    .define_method("load_at_most_ones_in_sat_presolve", &SatParameters::load_at_most_ones_in_sat_presolve)
    .define_method("load_at_most_ones_in_sat_presolve=", &SatParameters::set_load_at_most_ones_in_sat_presolve)
    .define_method("log_prefix", &SatParameters::log_prefix)
    // .define_method("log_prefix=", &SatParameters::set_log_prefix)
    .define_method("log_search_progress", &SatParameters::log_search_progress)
    .define_method("log_search_progress=", &SatParameters::set_log_search_progress)
    .define_method("log_subsolver_statistics", &SatParameters::log_subsolver_statistics)
    .define_method("log_subsolver_statistics=", &SatParameters::set_log_subsolver_statistics)
    .define_method("log_to_response", &SatParameters::log_to_response)
    .define_method("log_to_response=", &SatParameters::set_log_to_response)
    .define_method("log_to_stdout", &SatParameters::log_to_stdout)
    .define_method("log_to_stdout=", &SatParameters::set_log_to_stdout)
    .define_method("lp_dual_tolerance", &SatParameters::lp_dual_tolerance)
    .define_method("lp_dual_tolerance=", &SatParameters::set_lp_dual_tolerance)
    .define_method("lp_primal_tolerance", &SatParameters::lp_primal_tolerance)
    .define_method("lp_primal_tolerance=", &SatParameters::set_lp_primal_tolerance)
    .define_method("max_all_diff_cut_size", &SatParameters::max_all_diff_cut_size)
    .define_method("max_all_diff_cut_size=", &SatParameters::set_max_all_diff_cut_size)
    .define_method("max_alldiff_domain_size", &SatParameters::max_alldiff_domain_size)
    .define_method("max_alldiff_domain_size=", &SatParameters::set_max_alldiff_domain_size)
    .define_method("max_backjump_levels", &SatParameters::max_backjump_levels)
    .define_method("max_backjump_levels=", &SatParameters::set_max_backjump_levels)
    .define_method("max_clause_activity_value", &SatParameters::max_clause_activity_value)
    .define_method("max_clause_activity_value=", &SatParameters::set_max_clause_activity_value)
    .define_method("max_consecutive_inactive_count", &SatParameters::max_consecutive_inactive_count)
    .define_method("max_consecutive_inactive_count=", &SatParameters::set_max_consecutive_inactive_count)
    .define_method("max_cut_rounds_at_level_zero", &SatParameters::max_cut_rounds_at_level_zero)
    .define_method("max_cut_rounds_at_level_zero=", &SatParameters::set_max_cut_rounds_at_level_zero)
    .define_method("max_deterministic_time", &SatParameters::max_deterministic_time)
    .define_method("max_deterministic_time=", &SatParameters::set_max_deterministic_time)
    .define_method("max_domain_size_for_linear2_expansion", &SatParameters::max_domain_size_for_linear2_expansion)
    .define_method("max_domain_size_for_linear2_expansion=", &SatParameters::set_max_domain_size_for_linear2_expansion)
    .define_method("max_domain_size_when_encoding_eq_neq_constraints", &SatParameters::max_domain_size_when_encoding_eq_neq_constraints)
    .define_method("max_domain_size_when_encoding_eq_neq_constraints=", &SatParameters::set_max_domain_size_when_encoding_eq_neq_constraints)
    .define_method("max_drat_time_in_seconds", &SatParameters::max_drat_time_in_seconds)
    .define_method("max_drat_time_in_seconds=", &SatParameters::set_max_drat_time_in_seconds)
    .define_method("max_integer_rounding_scaling", &SatParameters::max_integer_rounding_scaling)
    .define_method("max_integer_rounding_scaling=", &SatParameters::set_max_integer_rounding_scaling)
    .define_method("max_lin_max_size_for_expansion", &SatParameters::max_lin_max_size_for_expansion)
    .define_method("max_lin_max_size_for_expansion=", &SatParameters::set_max_lin_max_size_for_expansion)
    .define_method("max_memory_in_mb", &SatParameters::max_memory_in_mb)
    .define_method("max_memory_in_mb=", &SatParameters::set_max_memory_in_mb)
    .define_method("max_num_cuts", &SatParameters::max_num_cuts)
    .define_method("max_num_cuts=", &SatParameters::set_max_num_cuts)
    .define_method("max_num_deterministic_batches", &SatParameters::max_num_deterministic_batches)
    .define_method("max_num_deterministic_batches=", &SatParameters::set_max_num_deterministic_batches)
    .define_method("max_num_intervals_for_timetable_edge_finding", &SatParameters::max_num_intervals_for_timetable_edge_finding)
    .define_method("max_num_intervals_for_timetable_edge_finding=", &SatParameters::set_max_num_intervals_for_timetable_edge_finding)
    .define_method("max_number_of_conflicts", &SatParameters::max_number_of_conflicts)
    .define_method("max_number_of_conflicts=", &SatParameters::set_max_number_of_conflicts)
    .define_method("max_pairs_pairwise_reasoning_in_no_overlap_2d", &SatParameters::max_pairs_pairwise_reasoning_in_no_overlap_2d)
    .define_method("max_pairs_pairwise_reasoning_in_no_overlap_2d=", &SatParameters::set_max_pairs_pairwise_reasoning_in_no_overlap_2d)
    .define_method("max_presolve_iterations", &SatParameters::max_presolve_iterations)
    .define_method("max_presolve_iterations=", &SatParameters::set_max_presolve_iterations)
    .define_method("max_sat_reverse_assumption_order", &SatParameters::max_sat_reverse_assumption_order)
    .define_method("max_sat_reverse_assumption_order=", &SatParameters::set_max_sat_reverse_assumption_order)
    .define_method("max_size_to_create_precedence_literals_in_disjunctive", &SatParameters::max_size_to_create_precedence_literals_in_disjunctive)
    .define_method("max_size_to_create_precedence_literals_in_disjunctive=", &SatParameters::set_max_size_to_create_precedence_literals_in_disjunctive)
    .define_method("max_time_in_seconds", &SatParameters::max_time_in_seconds)
    .define_method("max_time_in_seconds=", &SatParameters::set_max_time_in_seconds)
    .define_method("max_variable_activity_value", &SatParameters::max_variable_activity_value)
    .define_method("max_variable_activity_value=", &SatParameters::set_max_variable_activity_value)
    .define_method("maximum_regions_to_split_in_disconnected_no_overlap_2d", &SatParameters::maximum_regions_to_split_in_disconnected_no_overlap_2d)
    .define_method("maximum_regions_to_split_in_disconnected_no_overlap_2d=", &SatParameters::set_maximum_regions_to_split_in_disconnected_no_overlap_2d)
    .define_method("merge_at_most_one_work_limit", &SatParameters::merge_at_most_one_work_limit)
    .define_method("merge_at_most_one_work_limit=", &SatParameters::set_merge_at_most_one_work_limit)
    .define_method("merge_no_overlap_work_limit", &SatParameters::merge_no_overlap_work_limit)
    .define_method("merge_no_overlap_work_limit=", &SatParameters::set_merge_no_overlap_work_limit)
    .define_method("min_orthogonality_for_lp_constraints", &SatParameters::min_orthogonality_for_lp_constraints)
    .define_method("min_orthogonality_for_lp_constraints=", &SatParameters::set_min_orthogonality_for_lp_constraints)
    .define_method("minimize_reduction_during_pb_resolution", &SatParameters::minimize_reduction_during_pb_resolution)
    .define_method("minimize_reduction_during_pb_resolution=", &SatParameters::set_minimize_reduction_during_pb_resolution)
    .define_method("minimize_shared_clauses", &SatParameters::minimize_shared_clauses)
    .define_method("minimize_shared_clauses=", &SatParameters::set_minimize_shared_clauses)
    .define_method("mip_automatically_scale_variables", &SatParameters::mip_automatically_scale_variables)
    .define_method("mip_automatically_scale_variables=", &SatParameters::set_mip_automatically_scale_variables)
    .define_method("mip_check_precision", &SatParameters::mip_check_precision)
    .define_method("mip_check_precision=", &SatParameters::set_mip_check_precision)
    .define_method("mip_compute_true_objective_bound", &SatParameters::mip_compute_true_objective_bound)
    .define_method("mip_compute_true_objective_bound=", &SatParameters::set_mip_compute_true_objective_bound)
    .define_method("mip_drop_tolerance", &SatParameters::mip_drop_tolerance)
    .define_method("mip_drop_tolerance=", &SatParameters::set_mip_drop_tolerance)
    .define_method("mip_max_activity_exponent", &SatParameters::mip_max_activity_exponent)
    .define_method("mip_max_activity_exponent=", &SatParameters::set_mip_max_activity_exponent)
    .define_method("mip_max_bound", &SatParameters::mip_max_bound)
    .define_method("mip_max_bound=", &SatParameters::set_mip_max_bound)
    .define_method("mip_max_valid_magnitude", &SatParameters::mip_max_valid_magnitude)
    .define_method("mip_max_valid_magnitude=", &SatParameters::set_mip_max_valid_magnitude)
    .define_method("mip_presolve_level", &SatParameters::mip_presolve_level)
    .define_method("mip_presolve_level=", &SatParameters::set_mip_presolve_level)
    .define_method("mip_scale_large_domain", &SatParameters::mip_scale_large_domain)
    .define_method("mip_scale_large_domain=", &SatParameters::set_mip_scale_large_domain)
    .define_method("mip_treat_high_magnitude_bounds_as_infinity", &SatParameters::mip_treat_high_magnitude_bounds_as_infinity)
    .define_method("mip_treat_high_magnitude_bounds_as_infinity=", &SatParameters::set_mip_treat_high_magnitude_bounds_as_infinity)
    .define_method("mip_var_scaling", &SatParameters::mip_var_scaling)
    .define_method("mip_var_scaling=", &SatParameters::set_mip_var_scaling)
    .define_method("mip_wanted_precision", &SatParameters::mip_wanted_precision)
    .define_method("mip_wanted_precision=", &SatParameters::set_mip_wanted_precision)
    .define_method("name", &SatParameters::name)
    // .define_method("name=", &SatParameters::set_name)
    .define_method("new_constraints_batch_size", &SatParameters::new_constraints_batch_size)
    .define_method("new_constraints_batch_size=", &SatParameters::set_new_constraints_batch_size)
    .define_method("new_linear_propagation", &SatParameters::new_linear_propagation)
    .define_method("new_linear_propagation=", &SatParameters::set_new_linear_propagation)
    .define_method("no_overlap_2d_boolean_relations_limit", &SatParameters::no_overlap_2d_boolean_relations_limit)
    .define_method("no_overlap_2d_boolean_relations_limit=", &SatParameters::set_no_overlap_2d_boolean_relations_limit)
    .define_method("num_conflicts_before_strategy_changes", &SatParameters::num_conflicts_before_strategy_changes)
    .define_method("num_conflicts_before_strategy_changes=", &SatParameters::set_num_conflicts_before_strategy_changes)
    .define_method("num_full_subsolvers", &SatParameters::num_full_subsolvers)
    .define_method("num_full_subsolvers=", &SatParameters::set_num_full_subsolvers)
    .define_method("num_search_workers", &SatParameters::num_search_workers)
    .define_method("num_search_workers=", &SatParameters::set_num_search_workers)
    .define_method("num_violation_ls", &SatParameters::num_violation_ls)
    .define_method("num_violation_ls=", &SatParameters::set_num_violation_ls)
    .define_method("num_workers", &SatParameters::num_workers)
    .define_method("num_workers=", &SatParameters::set_num_workers)
    .define_method("only_add_cuts_at_level_zero", &SatParameters::only_add_cuts_at_level_zero)
    .define_method("only_add_cuts_at_level_zero=", &SatParameters::set_only_add_cuts_at_level_zero)
    .define_method("only_solve_ip", &SatParameters::only_solve_ip)
    .define_method("only_solve_ip=", &SatParameters::set_only_solve_ip)
    .define_method("optimize_with_core", &SatParameters::optimize_with_core)
    .define_method("optimize_with_core=", &SatParameters::set_optimize_with_core)
    .define_method("optimize_with_lb_tree_search", &SatParameters::optimize_with_lb_tree_search)
    .define_method("optimize_with_lb_tree_search=", &SatParameters::set_optimize_with_lb_tree_search)
    .define_method("optimize_with_max_hs", &SatParameters::optimize_with_max_hs)
    .define_method("optimize_with_max_hs=", &SatParameters::set_optimize_with_max_hs)
    .define_method("output_drat_proof", &SatParameters::output_drat_proof)
    .define_method("output_drat_proof=", &SatParameters::set_output_drat_proof)
    .define_method("output_lrat_proof", &SatParameters::output_lrat_proof)
    .define_method("output_lrat_proof=", &SatParameters::set_output_lrat_proof)
    .define_method("pb_cleanup_increment", &SatParameters::pb_cleanup_increment)
    .define_method("pb_cleanup_increment=", &SatParameters::set_pb_cleanup_increment)
    .define_method("pb_cleanup_ratio", &SatParameters::pb_cleanup_ratio)
    .define_method("pb_cleanup_ratio=", &SatParameters::set_pb_cleanup_ratio)
    .define_method("permute_presolve_constraint_order", &SatParameters::permute_presolve_constraint_order)
    .define_method("permute_presolve_constraint_order=", &SatParameters::set_permute_presolve_constraint_order)
    .define_method("permute_variable_randomly", &SatParameters::permute_variable_randomly)
    .define_method("permute_variable_randomly=", &SatParameters::set_permute_variable_randomly)
    .define_method("polarity_exploit_ls_hints", &SatParameters::polarity_exploit_ls_hints)
    .define_method("polarity_exploit_ls_hints=", &SatParameters::set_polarity_exploit_ls_hints)
    .define_method("polarity_rephase_increment", &SatParameters::polarity_rephase_increment)
    .define_method("polarity_rephase_increment=", &SatParameters::set_polarity_rephase_increment)
    .define_method("polish_lp_solution", &SatParameters::polish_lp_solution)
    .define_method("polish_lp_solution=", &SatParameters::set_polish_lp_solution)
    .define_method("presolve_blocked_clause", &SatParameters::presolve_blocked_clause)
    .define_method("presolve_blocked_clause=", &SatParameters::set_presolve_blocked_clause)
    .define_method("presolve_bva_threshold", &SatParameters::presolve_bva_threshold)
    .define_method("presolve_bva_threshold=", &SatParameters::set_presolve_bva_threshold)
    .define_method("presolve_bve_clause_weight", &SatParameters::presolve_bve_clause_weight)
    .define_method("presolve_bve_clause_weight=", &SatParameters::set_presolve_bve_clause_weight)
    .define_method("presolve_bve_threshold", &SatParameters::presolve_bve_threshold)
    .define_method("presolve_bve_threshold=", &SatParameters::set_presolve_bve_threshold)
    .define_method("presolve_extract_integer_enforcement", &SatParameters::presolve_extract_integer_enforcement)
    .define_method("presolve_extract_integer_enforcement=", &SatParameters::set_presolve_extract_integer_enforcement)
    .define_method("presolve_inclusion_work_limit", &SatParameters::presolve_inclusion_work_limit)
    .define_method("presolve_inclusion_work_limit=", &SatParameters::set_presolve_inclusion_work_limit)
    .define_method("presolve_probing_deterministic_time_limit", &SatParameters::presolve_probing_deterministic_time_limit)
    .define_method("presolve_probing_deterministic_time_limit=", &SatParameters::set_presolve_probing_deterministic_time_limit)
    .define_method("presolve_substitution_level", &SatParameters::presolve_substitution_level)
    .define_method("presolve_substitution_level=", &SatParameters::set_presolve_substitution_level)
    .define_method("presolve_use_bva", &SatParameters::presolve_use_bva)
    .define_method("presolve_use_bva=", &SatParameters::set_presolve_use_bva)
    .define_method("probing_deterministic_time_limit", &SatParameters::probing_deterministic_time_limit)
    .define_method("probing_deterministic_time_limit=", &SatParameters::set_probing_deterministic_time_limit)
    .define_method("probing_num_combinations_limit", &SatParameters::probing_num_combinations_limit)
    .define_method("probing_num_combinations_limit=", &SatParameters::set_probing_num_combinations_limit)
    .define_method("propagation_loop_detection_factor", &SatParameters::propagation_loop_detection_factor)
    .define_method("propagation_loop_detection_factor=", &SatParameters::set_propagation_loop_detection_factor)
    .define_method("pseudo_cost_reliability_threshold", &SatParameters::pseudo_cost_reliability_threshold)
    .define_method("pseudo_cost_reliability_threshold=", &SatParameters::set_pseudo_cost_reliability_threshold)
    .define_method("push_all_tasks_toward_start", &SatParameters::push_all_tasks_toward_start)
    .define_method("push_all_tasks_toward_start=", &SatParameters::set_push_all_tasks_toward_start)
    .define_method("random_branches_ratio", &SatParameters::random_branches_ratio)
    .define_method("random_branches_ratio=", &SatParameters::set_random_branches_ratio)
    .define_method("random_polarity_ratio", &SatParameters::random_polarity_ratio)
    .define_method("random_polarity_ratio=", &SatParameters::set_random_polarity_ratio)
    .define_method("random_seed", &SatParameters::random_seed)
    .define_method("random_seed=", &SatParameters::set_random_seed)
    .define_method("randomize_search", &SatParameters::randomize_search)
    .define_method("randomize_search=", &SatParameters::set_randomize_search)
    .define_method("relative_gap_limit", &SatParameters::relative_gap_limit)
    .define_method("relative_gap_limit=", &SatParameters::set_relative_gap_limit)
    .define_method("remove_fixed_variables_early", &SatParameters::remove_fixed_variables_early)
    .define_method("remove_fixed_variables_early=", &SatParameters::set_remove_fixed_variables_early)
    .define_method("repair_hint", &SatParameters::repair_hint)
    .define_method("repair_hint=", &SatParameters::set_repair_hint)
    .define_method("restart_dl_average_ratio", &SatParameters::restart_dl_average_ratio)
    .define_method("restart_dl_average_ratio=", &SatParameters::set_restart_dl_average_ratio)
    .define_method("restart_lbd_average_ratio", &SatParameters::restart_lbd_average_ratio)
    .define_method("restart_lbd_average_ratio=", &SatParameters::set_restart_lbd_average_ratio)
    .define_method("restart_period", &SatParameters::restart_period)
    .define_method("restart_period=", &SatParameters::set_restart_period)
    .define_method("restart_running_window_size", &SatParameters::restart_running_window_size)
    .define_method("restart_running_window_size=", &SatParameters::set_restart_running_window_size)
    .define_method("root_lp_iterations", &SatParameters::root_lp_iterations)
    .define_method("root_lp_iterations=", &SatParameters::set_root_lp_iterations)
    .define_method("routing_cut_dp_effort", &SatParameters::routing_cut_dp_effort)
    .define_method("routing_cut_dp_effort=", &SatParameters::set_routing_cut_dp_effort)
    .define_method("routing_cut_max_infeasible_path_length", &SatParameters::routing_cut_max_infeasible_path_length)
    .define_method("routing_cut_max_infeasible_path_length=", &SatParameters::set_routing_cut_max_infeasible_path_length)
    .define_method("routing_cut_subset_size_for_binary_relation_bound", &SatParameters::routing_cut_subset_size_for_binary_relation_bound)
    .define_method("routing_cut_subset_size_for_binary_relation_bound=", &SatParameters::set_routing_cut_subset_size_for_binary_relation_bound)
    .define_method("routing_cut_subset_size_for_exact_binary_relation_bound", &SatParameters::routing_cut_subset_size_for_exact_binary_relation_bound)
    .define_method("routing_cut_subset_size_for_exact_binary_relation_bound=", &SatParameters::set_routing_cut_subset_size_for_exact_binary_relation_bound)
    .define_method("routing_cut_subset_size_for_shortest_paths_bound", &SatParameters::routing_cut_subset_size_for_shortest_paths_bound)
    .define_method("routing_cut_subset_size_for_shortest_paths_bound=", &SatParameters::set_routing_cut_subset_size_for_shortest_paths_bound)
    .define_method("routing_cut_subset_size_for_tight_binary_relation_bound", &SatParameters::routing_cut_subset_size_for_tight_binary_relation_bound)
    .define_method("routing_cut_subset_size_for_tight_binary_relation_bound=", &SatParameters::set_routing_cut_subset_size_for_tight_binary_relation_bound)
    .define_method("save_lp_basis_in_lb_tree_search", &SatParameters::save_lp_basis_in_lb_tree_search)
    .define_method("save_lp_basis_in_lb_tree_search=", &SatParameters::set_save_lp_basis_in_lb_tree_search)
    .define_method("search_random_variable_pool_size", &SatParameters::search_random_variable_pool_size)
    .define_method("search_random_variable_pool_size=", &SatParameters::set_search_random_variable_pool_size)
    .define_method("share_binary_clauses", &SatParameters::share_binary_clauses)
    .define_method("share_binary_clauses=", &SatParameters::set_share_binary_clauses)
    .define_method("share_glue_clauses", &SatParameters::share_glue_clauses)
    .define_method("share_glue_clauses=", &SatParameters::set_share_glue_clauses)
    .define_method("share_glue_clauses_dtime", &SatParameters::share_glue_clauses_dtime)
    .define_method("share_glue_clauses_dtime=", &SatParameters::set_share_glue_clauses_dtime)
    .define_method("share_level_zero_bounds", &SatParameters::share_level_zero_bounds)
    .define_method("share_level_zero_bounds=", &SatParameters::set_share_level_zero_bounds)
    .define_method("share_linear2_bounds", &SatParameters::share_linear2_bounds)
    .define_method("share_linear2_bounds=", &SatParameters::set_share_linear2_bounds)
    .define_method("share_objective_bounds", &SatParameters::share_objective_bounds)
    .define_method("share_objective_bounds=", &SatParameters::set_share_objective_bounds)
    .define_method("shared_tree_balance_tolerance", &SatParameters::shared_tree_balance_tolerance)
    .define_method("shared_tree_balance_tolerance=", &SatParameters::set_shared_tree_balance_tolerance)
    .define_method("shared_tree_max_nodes_per_worker", &SatParameters::shared_tree_max_nodes_per_worker)
    .define_method("shared_tree_max_nodes_per_worker=", &SatParameters::set_shared_tree_max_nodes_per_worker)
    .define_method("shared_tree_num_workers", &SatParameters::shared_tree_num_workers)
    .define_method("shared_tree_num_workers=", &SatParameters::set_shared_tree_num_workers)
    .define_method("shared_tree_open_leaves_per_worker", &SatParameters::shared_tree_open_leaves_per_worker)
    .define_method("shared_tree_open_leaves_per_worker=", &SatParameters::set_shared_tree_open_leaves_per_worker)
    .define_method("shared_tree_split_min_dtime", &SatParameters::shared_tree_split_min_dtime)
    .define_method("shared_tree_split_min_dtime=", &SatParameters::set_shared_tree_split_min_dtime)
    .define_method("shared_tree_worker_enable_phase_sharing", &SatParameters::shared_tree_worker_enable_phase_sharing)
    .define_method("shared_tree_worker_enable_phase_sharing=", &SatParameters::set_shared_tree_worker_enable_phase_sharing)
    .define_method("shared_tree_worker_enable_trail_sharing", &SatParameters::shared_tree_worker_enable_trail_sharing)
    .define_method("shared_tree_worker_enable_trail_sharing=", &SatParameters::set_shared_tree_worker_enable_trail_sharing)
    .define_method("shared_tree_worker_min_restarts_per_subtree", &SatParameters::shared_tree_worker_min_restarts_per_subtree)
    .define_method("shared_tree_worker_min_restarts_per_subtree=", &SatParameters::set_shared_tree_worker_min_restarts_per_subtree)
    .define_method("shaving_deterministic_time_in_probing_search", &SatParameters::shaving_deterministic_time_in_probing_search)
    .define_method("shaving_deterministic_time_in_probing_search=", &SatParameters::set_shaving_deterministic_time_in_probing_search)
    .define_method("shaving_search_deterministic_time", &SatParameters::shaving_search_deterministic_time)
    .define_method("shaving_search_deterministic_time=", &SatParameters::set_shaving_search_deterministic_time)
    .define_method("shaving_search_threshold", &SatParameters::shaving_search_threshold)
    .define_method("shaving_search_threshold=", &SatParameters::set_shaving_search_threshold)
    .define_method("solution_pool_diversity_limit", &SatParameters::solution_pool_diversity_limit)
    .define_method("solution_pool_diversity_limit=", &SatParameters::set_solution_pool_diversity_limit)
    .define_method("solution_pool_size", &SatParameters::solution_pool_size)
    .define_method("solution_pool_size=", &SatParameters::set_solution_pool_size)
    .define_method("stop_after_first_solution", &SatParameters::stop_after_first_solution)
    .define_method("stop_after_first_solution=", &SatParameters::set_stop_after_first_solution)
    .define_method("stop_after_presolve", &SatParameters::stop_after_presolve)
    .define_method("stop_after_presolve=", &SatParameters::set_stop_after_presolve)
    .define_method("stop_after_root_propagation", &SatParameters::stop_after_root_propagation)
    .define_method("stop_after_root_propagation=", &SatParameters::set_stop_after_root_propagation)
    .define_method("strategy_change_increase_ratio", &SatParameters::strategy_change_increase_ratio)
    .define_method("strategy_change_increase_ratio=", &SatParameters::set_strategy_change_increase_ratio)
    .define_method("subsume_during_vivification", &SatParameters::subsume_during_vivification)
    .define_method("subsume_during_vivification=", &SatParameters::set_subsume_during_vivification)
    .define_method("subsumption_during_conflict_analysis", &SatParameters::subsumption_during_conflict_analysis)
    .define_method("subsumption_during_conflict_analysis=", &SatParameters::set_subsumption_during_conflict_analysis)
    .define_method("symmetry_detection_deterministic_time_limit", &SatParameters::symmetry_detection_deterministic_time_limit)
    .define_method("symmetry_detection_deterministic_time_limit=", &SatParameters::set_symmetry_detection_deterministic_time_limit)
    .define_method("symmetry_level", &SatParameters::symmetry_level)
    .define_method("symmetry_level=", &SatParameters::set_symmetry_level)
    .define_method("table_compression_level", &SatParameters::table_compression_level)
    .define_method("table_compression_level=", &SatParameters::set_table_compression_level)
    .define_method("transitive_precedences_work_limit", &SatParameters::transitive_precedences_work_limit)
    .define_method("transitive_precedences_work_limit=", &SatParameters::set_transitive_precedences_work_limit)
    .define_method("use_absl_random", &SatParameters::use_absl_random)
    .define_method("use_absl_random=", &SatParameters::set_use_absl_random)
    .define_method("use_all_different_for_circuit", &SatParameters::use_all_different_for_circuit)
    .define_method("use_all_different_for_circuit=", &SatParameters::set_use_all_different_for_circuit)
    .define_method("use_area_energetic_reasoning_in_no_overlap_2d", &SatParameters::use_area_energetic_reasoning_in_no_overlap_2d)
    .define_method("use_area_energetic_reasoning_in_no_overlap_2d=", &SatParameters::set_use_area_energetic_reasoning_in_no_overlap_2d)
    .define_method("use_blocking_restart", &SatParameters::use_blocking_restart)
    .define_method("use_blocking_restart=", &SatParameters::set_use_blocking_restart)
    .define_method("use_chronological_backtracking", &SatParameters::use_chronological_backtracking)
    .define_method("use_chronological_backtracking=", &SatParameters::set_use_chronological_backtracking)
    .define_method("use_combined_no_overlap", &SatParameters::use_combined_no_overlap)
    .define_method("use_combined_no_overlap=", &SatParameters::set_use_combined_no_overlap)
    .define_method("use_conservative_scale_overload_checker", &SatParameters::use_conservative_scale_overload_checker)
    .define_method("use_conservative_scale_overload_checker=", &SatParameters::set_use_conservative_scale_overload_checker)
    .define_method("use_disjunctive_constraint_in_cumulative", &SatParameters::use_disjunctive_constraint_in_cumulative)
    .define_method("use_disjunctive_constraint_in_cumulative=", &SatParameters::set_use_disjunctive_constraint_in_cumulative)
    .define_method("use_dual_scheduling_heuristics", &SatParameters::use_dual_scheduling_heuristics)
    .define_method("use_dual_scheduling_heuristics=", &SatParameters::set_use_dual_scheduling_heuristics)
    .define_method("use_dynamic_precedence_in_cumulative", &SatParameters::use_dynamic_precedence_in_cumulative)
    .define_method("use_dynamic_precedence_in_cumulative=", &SatParameters::set_use_dynamic_precedence_in_cumulative)
    .define_method("use_dynamic_precedence_in_disjunctive", &SatParameters::use_dynamic_precedence_in_disjunctive)
    .define_method("use_dynamic_precedence_in_disjunctive=", &SatParameters::set_use_dynamic_precedence_in_disjunctive)
    .define_method("use_energetic_reasoning_in_no_overlap_2d", &SatParameters::use_energetic_reasoning_in_no_overlap_2d)
    .define_method("use_energetic_reasoning_in_no_overlap_2d=", &SatParameters::set_use_energetic_reasoning_in_no_overlap_2d)
    .define_method("use_erwa_heuristic", &SatParameters::use_erwa_heuristic)
    .define_method("use_erwa_heuristic=", &SatParameters::set_use_erwa_heuristic)
    .define_method("use_exact_lp_reason", &SatParameters::use_exact_lp_reason)
    .define_method("use_exact_lp_reason=", &SatParameters::set_use_exact_lp_reason)
    .define_method("use_extended_probing", &SatParameters::use_extended_probing)
    .define_method("use_extended_probing=", &SatParameters::set_use_extended_probing)
    .define_method("use_feasibility_jump", &SatParameters::use_feasibility_jump)
    .define_method("use_feasibility_jump=", &SatParameters::set_use_feasibility_jump)
    .define_method("use_feasibility_pump", &SatParameters::use_feasibility_pump)
    .define_method("use_feasibility_pump=", &SatParameters::set_use_feasibility_pump)
    .define_method("use_hard_precedences_in_cumulative", &SatParameters::use_hard_precedences_in_cumulative)
    .define_method("use_hard_precedences_in_cumulative=", &SatParameters::set_use_hard_precedences_in_cumulative)
    .define_method("use_implied_bounds", &SatParameters::use_implied_bounds)
    .define_method("use_implied_bounds=", &SatParameters::set_use_implied_bounds)
    .define_method("use_lb_relax_lns", &SatParameters::use_lb_relax_lns)
    .define_method("use_lb_relax_lns=", &SatParameters::set_use_lb_relax_lns)
    .define_method("use_linear3_for_no_overlap_2d_precedences", &SatParameters::use_linear3_for_no_overlap_2d_precedences)
    .define_method("use_linear3_for_no_overlap_2d_precedences=", &SatParameters::set_use_linear3_for_no_overlap_2d_precedences)
    .define_method("use_lns", &SatParameters::use_lns)
    .define_method("use_lns=", &SatParameters::set_use_lns)
    .define_method("use_lns_only", &SatParameters::use_lns_only)
    .define_method("use_lns_only=", &SatParameters::set_use_lns_only)
    .define_method("use_ls_only", &SatParameters::use_ls_only)
    .define_method("use_ls_only=", &SatParameters::set_use_ls_only)
    .define_method("use_new_integer_conflict_resolution", &SatParameters::use_new_integer_conflict_resolution)
    .define_method("use_new_integer_conflict_resolution=", &SatParameters::set_use_new_integer_conflict_resolution)
    .define_method("use_objective_lb_search", &SatParameters::use_objective_lb_search)
    .define_method("use_objective_lb_search=", &SatParameters::set_use_objective_lb_search)
    .define_method("use_objective_shaving_search", &SatParameters::use_objective_shaving_search)
    .define_method("use_objective_shaving_search=", &SatParameters::set_use_objective_shaving_search)
    .define_method("use_optimization_hints", &SatParameters::use_optimization_hints)
    .define_method("use_optimization_hints=", &SatParameters::set_use_optimization_hints)
    .define_method("use_optional_variables", &SatParameters::use_optional_variables)
    .define_method("use_optional_variables=", &SatParameters::set_use_optional_variables)
    .define_method("use_overload_checker_in_cumulative", &SatParameters::use_overload_checker_in_cumulative)
    .define_method("use_overload_checker_in_cumulative=", &SatParameters::set_use_overload_checker_in_cumulative)
    .define_method("use_pb_resolution", &SatParameters::use_pb_resolution)
    .define_method("use_pb_resolution=", &SatParameters::set_use_pb_resolution)
    .define_method("use_phase_saving", &SatParameters::use_phase_saving)
    .define_method("use_phase_saving=", &SatParameters::set_use_phase_saving)
    .define_method("use_precedences_in_disjunctive_constraint", &SatParameters::use_precedences_in_disjunctive_constraint)
    .define_method("use_precedences_in_disjunctive_constraint=", &SatParameters::set_use_precedences_in_disjunctive_constraint)
    .define_method("use_probing_search", &SatParameters::use_probing_search)
    .define_method("use_probing_search=", &SatParameters::set_use_probing_search)
    .define_method("use_rins_lns", &SatParameters::use_rins_lns)
    .define_method("use_rins_lns=", &SatParameters::set_use_rins_lns)
    .define_method("use_sat_inprocessing", &SatParameters::use_sat_inprocessing)
    .define_method("use_sat_inprocessing=", &SatParameters::set_use_sat_inprocessing)
    .define_method("use_shared_tree_search", &SatParameters::use_shared_tree_search)
    .define_method("use_shared_tree_search=", &SatParameters::set_use_shared_tree_search)
    .define_method("use_strong_propagation_in_disjunctive", &SatParameters::use_strong_propagation_in_disjunctive)
    .define_method("use_strong_propagation_in_disjunctive=", &SatParameters::set_use_strong_propagation_in_disjunctive)
    .define_method("use_symmetry_in_lp", &SatParameters::use_symmetry_in_lp)
    .define_method("use_symmetry_in_lp=", &SatParameters::set_use_symmetry_in_lp)
    .define_method("use_timetable_edge_finding_in_cumulative", &SatParameters::use_timetable_edge_finding_in_cumulative)
    .define_method("use_timetable_edge_finding_in_cumulative=", &SatParameters::set_use_timetable_edge_finding_in_cumulative)
    .define_method("use_timetabling_in_no_overlap_2d", &SatParameters::use_timetabling_in_no_overlap_2d)
    .define_method("use_timetabling_in_no_overlap_2d=", &SatParameters::set_use_timetabling_in_no_overlap_2d)
    .define_method("use_try_edge_reasoning_in_no_overlap_2d", &SatParameters::use_try_edge_reasoning_in_no_overlap_2d)
    .define_method("use_try_edge_reasoning_in_no_overlap_2d=", &SatParameters::set_use_try_edge_reasoning_in_no_overlap_2d)
    .define_method("variable_activity_decay", &SatParameters::variable_activity_decay)
    .define_method("variable_activity_decay=", &SatParameters::set_variable_activity_decay)
    .define_method("variables_shaving_level", &SatParameters::variables_shaving_level)
    .define_method("variables_shaving_level=", &SatParameters::set_variables_shaving_level)
    .define_method("violation_ls_compound_move_probability", &SatParameters::violation_ls_compound_move_probability)
    .define_method("violation_ls_compound_move_probability=", &SatParameters::set_violation_ls_compound_move_probability)
    .define_method("violation_ls_perturbation_period", &SatParameters::violation_ls_perturbation_period)
    .define_method("violation_ls_perturbation_period=", &SatParameters::set_violation_ls_perturbation_period);

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
      [](CpModelBuilder& self, const IntVar& start, const IntVar& size, const IntVar& end, const std::string& name) {
        return self.NewIntervalVar(start, size, end).WithName(name);
      })
    .define_method(
      "new_optional_interval_var",
      [](CpModelBuilder& self, const IntVar& start, const IntVar& size, const IntVar& end, const BoolVar& presence, const std::string& name) {
        return self.NewOptionalIntervalVar(start, size, end, presence).WithName(name);
      })
    .define_method(
      "add_bool_or",
      [](CpModelBuilder& self, const std::vector<BoolVar>& literals) {
        return self.AddBoolOr(literals);
      })
    .define_method(
      "add_bool_and",
      [](CpModelBuilder& self, const std::vector<BoolVar>& literals) {
        return self.AddBoolAnd(literals);
      })
    .define_method(
      "add_bool_xor",
      [](CpModelBuilder& self, const std::vector<BoolVar>& literals) {
        return self.AddBoolXor(literals);
      })
    .define_method(
      "add_implication",
      [](CpModelBuilder& self, const BoolVar& a, const BoolVar& b) {
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
      [](CpModelBuilder& self, LinearExpr expr, const Domain& domain) {
        return self.AddLinearConstraint(expr, domain);
      })
    .define_method(
      "add_not_equal",
      [](CpModelBuilder& self, LinearExpr x, LinearExpr y) {
        return self.AddNotEqual(x, y);
      })
    .define_method(
      "add_all_different",
      [](CpModelBuilder& self, const std::vector<IntVar>& vars) {
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
      [](CpModelBuilder& self, const std::vector<IntVar>& variables, const std::vector<IntVar>& inverse_variables) {
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
      [](CpModelBuilder& self, const std::vector<IntervalVar>& vars) {
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
      [](CpModelBuilder& self, const BoolVar& lit) {
        self.AddAssumption(lit);
      })
    .define_method(
      "add_assumptions",
      [](CpModelBuilder& self, const std::vector<BoolVar>& literals) {
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
        if (!google::protobuf::TextFormat::PrintToString(self.Proto(), &proto_string)) {
          throw Rice::Exception(rb_eRuntimeError, "PrintToString failed");
        }
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
          throw std::runtime_error{"Unknown solver status"};
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
        Model m;
        m.Add(NewSatParameters(parameters));

        std::atomic<bool> done{false};
        Channel<CpSolverResponse> channel;
        Rice::Object ruby_thread;
        std::optional<Rice::Exception> exception;

        auto with_gvl = [](std::function<void()> f) {
          auto ruby_wrapper = [](void* arg) -> void* {
            (*static_cast<decltype(f)*>(arg))();
            return nullptr;
          };
          rb_thread_call_with_gvl(ruby_wrapper, &f);
        };

        auto ruby_observer = [&]() {
          return Rice::detail::no_gvl([&]() {
            while (true) {
              if (done.load() && channel.empty()) {
                break;
              }

              while (true) {
                std::optional<CpSolverResponse> response = channel.recv_timeout(std::chrono::milliseconds(10));
                if (!response) {
                  break;
                }

                bool stop = false;
                with_gvl([&]() {
                  try {
                    try {
                      callback.call("response=", response.value());
                      callback.call("on_solution_callback");
                      stop = static_cast<bool>(callback.attr_get("@stopped"));
                    } catch (const Rice::Exception& e) {
                      exception = e;
                      stop = true;
                    }
                    callback.call("response=", Object(Qnil));
                  } catch (const Rice::Exception& e) {
                    exception = e;
                    stop = true;
                  }
                });

                if (stop) {
                  StopSearch(&m);
                  return Qnil;
                }
              }

              with_gvl([]() {
                Rice::detail::protect(rb_thread_schedule);
              });
            }
            return Qnil;
          });
        };

        auto ruby_wrapper = [](void* arg) {
          return (*static_cast<decltype(ruby_observer)*>(arg))();
        };

        if (!callback.is_nil()) {
          ruby_thread = Rice::detail::protect([&]() {
            return rb_thread_create(ruby_wrapper, &ruby_observer);
          });

          m.Add(NewFeasibleSolutionObserver(
            [&](const CpSolverResponse& response) {
              channel.send(response);
            })
          );
        }

        CpSolverResponse response = Rice::detail::no_gvl([&]() {
          return SolveCpModel(model.Build(), &m);
        });

        if (!callback.is_nil()) {
          done = true;
          ruby_thread.call("value");

          if (exception.has_value()) {
            throw exception.value();
          }
        }

        return response;
      })
    .define_method(
      "_solution_integer_value",
      [](Object self, const CpSolverResponse& response, const IntVar& x) {
        return SolutionIntegerValue(response, x);
      })
    .define_method(
      "_solution_boolean_value",
      [](Object self, const CpSolverResponse& response, const BoolVar& x) {
        return SolutionBooleanValue(response, x);
      });
}
