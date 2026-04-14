require "mkmf-rice"

$CXXFLAGS << " -std=c++17 $(optflags) -DUSE_CBC -DOR_PROTO_DLL="

# show warnings
$CXXFLAGS << " -Wall -Wextra"

# hide or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-ignored-qualifiers -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations"

# hide Rice warnings
$CXXFLAGS << " -Wno-unused-private-field -Wno-implicit-fallthrough"

inc, lib = dir_config("or-tools")
if inc || lib
  inc ||= "/usr/local/include"
  lib ||= "/usr/local/lib"
  rpath = lib
else
  # download
  require_relative "vendor"

  inc = "#{$vendor_path}/include"
  lib = "#{$vendor_path}/lib"

  # make rpath relative
  # use double dollar sign and single quotes to escape properly
  rpath_prefix = RbConfig::CONFIG["host_os"].match?(/darwin/) ? "@loader_path" : "$$ORIGIN"
  rpath = "'#{rpath_prefix}/../../tmp/or-tools/lib'"
end

# find_header and find_library first check without adding path
# which can cause them to find system library
$INCFLAGS << " -I#{inc}"
$LDFLAGS.prepend("-Wl,-rpath,#{rpath} -L#{lib} ")
raise "OR-Tools not found" unless have_library("ortools")

create_makefile("or_tools/ext")
