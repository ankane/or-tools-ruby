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

  $INCFLAGS << " -I#{inc}"

  lib_dirs.each do |lib_dir|
    $LDFLAGS.prepend("-L#{lib_dir} ")
  end

  # Add rpath for all lib directories
  $LDFLAGS.prepend("-Wl,-rpath,#{rpath} ")

  # Check for libprotobuf.a in any of the lib directories
  libprotobuf_found = lib_dirs.any? { |dir| File.exist?("#{dir}/libprotobuf.a") }
  raise "libprotobuf.a not found" unless libprotobuf_found

  # Add libprotobuf.a to LDFLAGS
  $LDFLAGS << " #{lib_dirs.find { |dir| File.exist?("#{dir}/libprotobuf.a") }}/libprotobuf.a"

  raise "OR-Tools not found" unless have_library("ortools")
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


create_makefile("or_tools/ext")
