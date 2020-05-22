require "mkmf-rice"

# download
require_relative "vendor"

abort "Missing stdc++" unless have_library("stdc++")

$CXXFLAGS << " -std=c++11 -DUSE_CBC"

# or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-shorten-64-to-32 -Wno-ignored-qualifiers"

inc = "#{$vendor_path}/include"
lib = "#{$vendor_path}/lib"

$INCFLAGS << " -I#{inc}"

# make rpath relative
# use double dollar sign and single quotes to escape properly
rpath_prefix = RbConfig::CONFIG["host_os"] =~ /darwin/ ? "@loader_path" : "$$ORIGIN"
$LDFLAGS << " -Wl,-rpath,'#{rpath_prefix}/../../tmp/or-tools/lib'"

$LDFLAGS << " -L#{lib}"
abort "OR-Tools not found" unless have_library("ortools")

Dir["#{lib}/libabsl_*.a"].each do |lib|
  $LDFLAGS << " #{lib}"
end

create_makefile("or_tools/ext")
