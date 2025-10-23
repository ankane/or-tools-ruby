require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

task default: :test

Rake::ExtensionTask.new("or-tools") do |ext|
  ext.name = "ext"
  ext.lib_dir = "lib/or_tools"
end

task :remove_ext do
  path = "lib/or_tools/ext.bundle"
  File.unlink(path) if File.exist?(path)
end

Rake::Task["build"].enhance [:remove_ext]

task :update do
  require "digest"
  require "open-uri"
  require "tmpdir"

  version = "9.14.6206"
  distributions = [
    "arm64_macOS-15.5",
    "x86_64_macOS-15.5",
    "amd64_ubuntu-24.04",
    "amd64_ubuntu-22.04",
    "amd64_ubuntu-20.04",
    "amd64_debian-12",
    "amd64_debian-11",
    "amd64_archlinux"
  ]

  short_version = version.split(".").first(2).join(".")
  distributions.each do |dist|
    filename = "or-tools_#{dist}_cpp_v#{version}.tar.gz"
    url = "https://github.com/google/or-tools/releases/download/v#{short_version}/#{filename}"
    dest = "#{Dir.tmpdir}/#{filename}"
    unless File.exist?(dest)
      temp_dest = "#{dest}.tmp"
      success = system("wget", "-O", temp_dest, url)
      raise "Download failed" unless success
      File.rename(temp_dest, dest)
    end
    puts "#{dist}: #{Digest::SHA256.file(dest).hexdigest}"
  end
end

CLEAN.add("tmp/or-tools")
