require "mkmf-rice"
require_relative "vendor"

abort "Missing stdc++" unless have_library("stdc++")

$CXXFLAGS << " -std=c++11 -DUSE_CBC"

# or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-shorten-64-to-32 -Wno-ignored-qualifiers"

inc = "#{$vendor_path}/include"
lib = "#{$vendor_path}/lib"

$INCFLAGS << " -I#{inc}"

$LDFLAGS << " -Wl,-rpath,#{lib}"
$LDFLAGS << " -L#{lib}"
abort "OR-Tools not found" unless have_library("ortools")

Dir["#{lib}/libabsl_*.a"].each do |lib|
  $LDFLAGS << " #{lib}"
end

create_makefile("or_tools/ext")
