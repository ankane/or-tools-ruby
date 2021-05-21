require "mkmf-rice"

$CXXFLAGS << " -std=c++17 $(optflags) -DUSE_CBC"

# or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-shorten-64-to-32 -Wno-ignored-qualifiers"

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
  rpath_prefix = RbConfig::CONFIG["host_os"] =~ /darwin/ ? "@loader_path" : "$$ORIGIN"
  rpath = "'#{rpath_prefix}/../../tmp/or-tools/lib'"
end

$INCFLAGS << " -I#{inc}"

$LDFLAGS << " -Wl,-rpath,#{rpath}"
$LDFLAGS << " -L#{lib}"
raise "OR-Tools not found" unless have_library("ortools")

Dir["#{lib}/libabsl_*.a"].each do |lib|
  $LDFLAGS << " #{lib}"
end

create_makefile("or_tools/ext")
