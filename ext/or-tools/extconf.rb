require "mkmf-rice"

$CXXFLAGS << " -std=c++17 $(optflags) -DUSE_CBC"

# or-tools warnings
$CXXFLAGS << " -Wno-sign-compare -Wno-shorten-64-to-32 -Wno-ignored-qualifiers"

inc, lib = dir_config("or-tools")
if inc || lib
  inc ||= "/usr/local/include"
  lib ||= "/usr/local/lib"

  lib_dirs = lib.split(':')
  rpath = lib_dirs.join(':')

  # Find the first lib directory containing libprotobuf.a
  libprotobuf_dir = lib_dirs.find { |dir| File.exist?("#{dir}/libprotobuf.a") }
  raise "libprotobuf.a not found" unless libprotobuf_dir

  # -L flags for each lib directory
  lib_dirs_flags = lib_dirs.map { |lib_dir| "-L#{lib_dir} " }.join

  $INCFLAGS << " -I#{inc}"
  ld_flags = "-Wl,-rpath,#{rpath} #{lib_dirs_flags} #{libprotobuf_dir}/libprotobuf.a "
  $LDFLAGS.prepend(ld_flags)
else
  # download
  require_relative "vendor"

  inc = "#{$vendor_path}/include"
  lib = "#{$vendor_path}/lib"

  # make rpath relative
  # use double dollar sign and single quotes to escape properly
  rpath_prefix = RbConfig::CONFIG["host_os"] =~ /darwin/ ? "@loader_path" : "$$ORIGIN"
  rpath = "'#{rpath_prefix}/../../tmp/or-tools/lib'"

  $INCFLAGS << " -I#{inc}"
  $LDFLAGS.prepend("-Wl,-rpath,#{rpath} -L#{lib} #{lib}/libprotobuf.a ")
end

raise "OR-Tools not found" unless have_library("ortools")
create_makefile("or_tools/ext")
