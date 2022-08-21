#include <ortools/base/version.h>
#include <ortools/init/init.h>

#include "ext.h"

using operations_research::CppBridge;
using operations_research::CppFlags;

void init_assignment(Rice::Module& m);
void init_bin_packing(Rice::Module& m);
void init_constraint(Rice::Module& m);
void init_linear(Rice::Module& m);
void init_network_flows(Rice::Module& m);
void init_routing(Rice::Module& m);

extern "C"
void Init_ext()
{
  auto m = Rice::define_module("ORTools");

  m.define_singleton_function("lib_version", &operations_research::OrToolsVersionString);

  init_assignment(m);
  init_bin_packing(m);
  init_constraint(m);
  init_linear(m);
  init_network_flows(m);
  init_routing(m);

  // fix logging warning
  CppBridge::InitLogging("");
  CppFlags flags = CppFlags();
  flags.logtostderr = true;
  flags.log_prefix = false;
  CppBridge::SetFlags(flags);
}
