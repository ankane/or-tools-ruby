require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"
require "ruby_memcheck"

test_config = lambda do |t|
  t.pattern = "test/**/*_test.rb"
end
Rake::TestTask.new(&test_config)

namespace :test do
  RubyMemcheck::TestTask.new(:valgrind, &test_config)
end

task default: :test

Rake::ExtensionTask.new("or-tools") do |ext|
  ext.name = "ext"
  ext.lib_dir = "lib/or_tools"
end

task :remove_ext do
  Dir["lib/or_tools/ext.{bundle,so}"].each do |path|
    File.unlink(path)
  end
end

Rake::Task["build"].enhance [:remove_ext]

task :update do
  require "digest"
  require "open-uri"
  require "tmpdir"

  version = "10.0-rc.1"
  distributions = [
    "arm64-macos",
    "amd64-macos",
    "arm64-linux",
    "amd64-linux"
  ]

  distributions.each do |dist|
    filename = "ortools-#{dist}-cpp.zip"
    url = "https://github.com/google/or-tools/releases/download/v#{version}/#{filename}"
    dest = "#{Dir.tmpdir}/#{filename}"
    unless File.exist?(dest)
      temp_dest = "#{dest}.tmp"
      system "wget", "-O", temp_dest, url, exception: true
      File.rename(temp_dest, dest)
    end
    puts "#{dist}: #{Digest::SHA256.file(dest).hexdigest}"
  end
end

CLEAN.add("tmp/or-tools")
