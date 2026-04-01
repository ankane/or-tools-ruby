require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.15.6755"
# Lookup table based on the OS, Version, ARM?
platforms = {
  ["alpine", nil,     false] => ["or-tools_amd64_alpine-edge_cpp_v#{version}.tar.gz",  "f7324bb1be49dae7187441834d24e6f73eb7f93c13ea37d8b5fe45e9698ede2f"],
  ["arch",   nil,     false] => ["or-tools_amd64_archlinux_cpp_v#{version}.tar.gz",    "5505079f7b2a6d9379ba6ae446a3a639226d455ef1cfa32d2d23ffc4566e3a4b"],
  ["darwin", nil,     false] => ["or-tools_x86_64_macOS-26.2_cpp_v#{version}.tar.gz",  "d2d36482727520ccaff979eba16f53e6b2cabf40b6fd1126e4d3b34fad2fe851"],
  ["darwin", nil,     true]  => ["or-tools_arm64_macOS-26.2_cpp_v#{version}.tar.gz",   "de0400a45939a66ee13cd8360c230e830fc5e03a6ed5a8a8b60f58a39e4a67bc"],
  ["debian", "11",    false] => ["or-tools_amd64_debian-11_cpp_v#{version}.tar.gz",    "c6c4341ff8f9aae3e77f161ca8ea3bb0d22f35ff696596fd11ec51c5da6bd4f7"],
  ["debian", "12",    false] => ["or-tools_amd64_debian-12_cpp_v#{version}.tar.gz",    "b2c9870c8778eeb26c98742402da17da039c058fca7eca87be5c90832b04153c"],
  ["ubuntu", "20.04", false] => ["or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz", "cfe5068b0fe4bafff916ab1b75670b341e80571c8cfd8b647dfe3e97a233e836"],
  ["ubuntu", "22.04", false] => ["or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz", "0b30114d7c05f0596286bf3ef8d02adcf5f45be3b39273490e6bb74a2a9bd1ea"],
  ["ubuntu", "24.04", false] => ["or-tools_amd64_ubuntu-24.04_cpp_v#{version}.tar.gz", "6f389320672cee00b78aacefb2bde33fef0bb988c3b2735573b9fffd1047fbda"],
}

def detect_os
  arm = RbConfig::CONFIG["host_cpu"].match?(/arm|aarch64/i)

  return ['Windows', nil, arm] if Gem.win_platform?
  return ["darwin", nil, arm] if RbConfig::CONFIG["host_os"].match?(/darwin/i)

  # Try /etc/os-release with fallback to /usr/lib/os-release
  # https://www.freedesktop.org/software/systemd/man/os-release.html
  os_filename = File.exist?("/etc/os-release") ? "/etc/os-release" : "/usr/lib/os-release"

  # for safety, parse rather than source
  os_info = File.readlines(os_filename, chomp: true).to_h { |v| v.split("=", 2) }.transform_values { |v| v.delete_prefix('"').delete_suffix('"') } rescue {}

  [os_info["ID"], os_info["VERSION_ID"], arm]
end

os, os_version, arm = detect_os
filename, checksum = platforms[[os, os_version, arm]] || platforms[[os, nil, arm]]

unless filename
  platform =
    if os || os_version
      "#{os} #{os_version} #{RbConfig::CONFIG["host_cpu"]}"
    else
      "Unknown"
    end

  # there is a binary download for Windows
  # however, it's compiled with Visual Studio rather than MinGW (which RubyInstaller uses)
  raise <<~MSG
    Binary installation not available for this platform: #{platform}

    Build the OR-Tools C++ library from source, then run:
    bundle config build.or-tools --with-or-tools-dir=/path/to/or-tools

  MSG
end

short_version = version.split(".").first(2).join(".")
url = "https://github.com/google/or-tools/releases/download/v#{short_version}/#{filename}"

$stdout.sync = true

def download_file(url, download_path, redirects = 0)
  raise "Too many redirects" if redirects > 10

  uri = URI(url)
  location = nil

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request) do |response|
      case response
      when Net::HTTPRedirection
        location = response["location"]
      when Net::HTTPSuccess
        i = 0
        File.open(download_path, "wb") do |f|
          response.read_body do |chunk|
            f.write(chunk)

            # print progress
            putc "." if i % 50 == 0
            i += 1
          end
        end
        puts # newline
      else
        raise "Bad response"
      end
    end
  end

  # outside of Net::HTTP block to close previous connection
  download_file(location, download_path, redirects + 1) if location
end

# download
download_path = "#{Dir.tmpdir}/#{filename}"
unless File.exist?(download_path)
  puts "Downloading #{url}..."
  download_file(url, download_path)
end

# check integrity - do this regardless of if just downloaded
download_checksum = Digest::SHA256.file(download_path).hexdigest
raise "Bad checksum: #{download_checksum}" if download_checksum != checksum

path = File.expand_path("../../tmp/or-tools", __dir__)
FileUtils.mkdir_p(path)

# extract - can't use Gem::Package#extract_tar_gz from RubyGems
# since it limits filenames to 100 characters (doesn't support UStar format)
# for space, only keep licenses, include, and shared library
Dir.mktmpdir do |extract_path|
  tar_args = Gem.win_platform? ? ["--force-local"] : []
  system "tar", "zxf", download_path, "-C", extract_path, "--strip-components=1", *tar_args

  # include
  FileUtils.mv(File.join(extract_path, "include"), File.join(path, "include"))

  # shared library
  FileUtils.mkdir(File.join(path, "lib"))
  Dir.glob("lib/lib*{.dylib,.so,.so.*}", base: extract_path) do |file|
    next if file.include?("libprotoc.")
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end

  # licenses
  license_files = Dir.glob("**/*{LICENSE,LICENCE,NOTICE,COPYING,license,licence,notice,copying}*", base: extract_path)
  raise "License not found" unless license_files.any?
  license_files.each do |file|
    next if File.directory?(File.join(extract_path, file))
    FileUtils.mkdir_p(File.join(path, File.dirname(file)))
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end
end

# export
$vendor_path = path
