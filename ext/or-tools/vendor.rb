require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.11.4210"

arch = RbConfig::CONFIG["host_cpu"]
arm = arch.match?(/arm|aarch64/i)

if RbConfig::CONFIG["host_os"].match?(/darwin/i)
  if arm
    filename = "or-tools_arm64_macOS-14.6.1_cpp_v#{version}.tar.gz"
    checksum = "a106668eb1975c1672874ef24b4f8e2e56669467a63349e5ea8ef5419814c31b"
  else
    filename = "or-tools_x86_64_macOS-14.6.1_cpp_v#{version}.tar.gz"
    checksum = "cc87a7f8c68ec4fed6c6de6565b0b625f2f0047185a8a4449ef4b5a305b60e55"
  end
else
  # try /etc/os-release with fallback to /usr/lib/os-release
  # https://www.freedesktop.org/software/systemd/man/os-release.html
  os_filename = File.exist?("/etc/os-release") ? "/etc/os-release" : "/usr/lib/os-release"

  # for safety, parse rather than source
  os_info = File.readlines(os_filename, chomp: true).to_h { |v| v.split("=", 2) }.transform_values { |v| v.delete_prefix('"').delete_suffix('"') } rescue {}

  os = os_info["ID"]
  os_version = os_info["VERSION_ID"]

  if os == "ubuntu" && os_version == "24.04" && !arm
    filename = "or-tools_amd64_ubuntu-24.04_cpp_v#{version}.tar.gz"
    checksum = "71761d93171b111fca736647a6cd00cb9e606474df597a8b48f3f5f2c73d4c0f"
  elsif os == "ubuntu" && os_version == "22.04" && !arm
    filename = "or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz"
    checksum = "f613574d4eae01afd966c8bde199990cbd9fad46035e675d71f17f5c7477eed4"
  elsif os == "ubuntu" && os_version == "20.04" && !arm
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "190b85f4510cab55fcb50b9850a0e2f94b2bdf5e266580650efbc5aaab760683"
  elsif os == "debian" && os_version == "11" && !arm
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "a8354696f365aa13a2375da5f8f6cfd8785430681addcd887bfd194851dd4710"
  elsif os == "arch" && !arm
    filename = "or-tools_amd64_archlinux_cpp_v#{version}.tar.gz"
    checksum = "ac892a949d871294b7e26b0730440ab8629b4021bf3c1641bc7c8fb09b45081f"
  else
    platform =
      if Gem.win_platform?
        "Windows"
      elsif os || os_version
        "#{os} #{os_version} #{arch}"
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

  # licenses
  license_files = Dir.glob("**/*{LICENSE,LICENCE,NOTICE,COPYING,license,licence,notice,copying}*", base: extract_path)
  raise "License not found" unless license_files.any?
  license_files.each do |file|
    FileUtils.mkdir_p(File.join(path, File.dirname(file)))
    FileUtils.cp(File.join(extract_path, file), File.join(path, file))
  end

  # include
  FileUtils.cp_r(File.join(extract_path, "include"), File.join(path, "include"))

  # shared library
  FileUtils.mkdir(File.join(path, "lib"))
  Dir.glob("lib/libortools.{9.dylib,so.9}", base: extract_path) do |file|
    so_path = File.join(path, file)
    FileUtils.cp(File.join(extract_path, file), so_path)
    ext = file.end_with?(".dylib") ? "dylib" : "so"
    File.symlink(so_path, File.join(path, "lib/libortools.#{ext}"))
  end
  ["lib/libprotobuf.a"].each do |file|
    FileUtils.cp(File.join(extract_path, file), File.join(path, file))
  end
end

# export
$vendor_path = path
