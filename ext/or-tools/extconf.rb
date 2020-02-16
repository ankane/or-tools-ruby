require "mkmf-rice"

abort "Missing stdc++" unless have_library("stdc++")

$CXXFLAGS << " -std=c++11 -DUSE_CBC"

# or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-shorten-64-to-32 -Wno-ignored-qualifiers"

inc, lib = dir_config("or-tools")

inc ||= "/usr/local/include"
lib ||= "/usr/local/lib"

$INCFLAGS << " -I#{inc}"

$LDFLAGS << " -Wl,-rpath,#{lib}"
$LDFLAGS << " -L#{lib}"
$LDFLAGS << " -lortools"

%w(
  absl_city
  absl_time_zone
  absl_spinlock_wait
  absl_log_severity
  absl_failure_signal_handler
  absl_bad_optional_access
  absl_hash
  absl_raw_logging_internal
  absl_random_internal_pool_urbg
  absl_base
  absl_bad_any_cast_impl
  absl_periodic_sampler
  absl_random_distributions
  absl_flags_usage_internal
  absl_random_seed_sequences
  absl_throw_delegate
  absl_flags_handle
  absl_dynamic_annotations
  absl_debugging_internal
  absl_strings
  absl_flags
  absl_malloc_internal
  absl_str_format_internal
  absl_flags_usage
  absl_strings_internal
  absl_flags_program_name
  absl_flags_registry
  absl_int128
  absl_scoped_set_env
  absl_raw_hash_set
  absl_random_internal_seed_material
  absl_symbolize
  absl_random_internal_randen_slow
  absl_graphcycles_internal
  absl_exponential_biased
  absl_random_internal_randen_hwaes_impl
  absl_bad_variant_access
  absl_stacktrace
  absl_random_internal_randen_hwaes
  absl_flags_parse
  absl_random_internal_randen
  absl_random_internal_distribution_test_util
  absl_time
  absl_flags_config
  absl_synchronization
  absl_hashtablez_sampler
  absl_demangle_internal
  absl_leak_check
  absl_flags_marshalling
  absl_leak_check_disable
  absl_examine_stack
  absl_flags_internal
  absl_random_seed_gen_exception
  absl_civil_time
).each do |lib|
  $LDFLAGS << " -l#{lib}"
end

create_makefile("or_tools/ext")
