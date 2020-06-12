require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

Rake::ExtensionTask.new("or-tools") do |ext|
  ext.name = "ext"
  ext.lib_dir = "lib/or_tools"
end

task :remove_ext do
  path = "lib/or-tools/ext.bundle"
  File.unlink(path) if File.exist?(path)
end

Rake::Task["build"].enhance [:remove_ext]

task :update do
  require "digest"
  require "open-uri"
  require "tmpdir"

  version = "7.7.7810"
  distributions = ["MacOsX-10.15.5", "ubuntu-18.04", "ubuntu-16.04", "debian-10", "centos-8"]

  short_version = version.split(".").first(2).join(".")
  distributions.each do |dist|
    filename = "or-tools_#{dist}_v#{version}.tar.gz"
    url = "https://github.com/google/or-tools/releases/download/v#{short_version}/#{filename}"
    dest = "#{Dir.tmpdir}/#{filename}"
    system "wget", "-O", dest, url unless File.exist?(dest)
    puts "#{dist}: #{Digest::SHA256.file(dest).hexdigest}"
  end
end
