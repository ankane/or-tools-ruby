require "csv"
require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.9.3963"

arch = RbConfig::CONFIG["host_cpu"]
arm = arch =~ /arm|aarch64/i

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if arm
    filename = "or-tools_arm64_macOS-14.3.1_cpp_v#{version}.tar.gz"
    checksum = "d9cbb3168d948208f68193b5d4df5f68cfc80fa61350b1a0efd0810f5accd600"
  else
    filename = "or-tools_x86_64_macOS-14.3.1_cpp_v#{version}.tar.gz"
    checksum = "2fc0b9a9c26793de1626ff8e93f49458d600af85e991ec845d351d7f30ed786d"
  end
else
  # try /etc/os-release with fallback to /usr/lib/os-release
  # https://www.freedesktop.org/software/systemd/man/os-release.html
  os_filename = File.exist?("/etc/os-release") ? "/etc/os-release" : "/usr/lib/os-release"

  # for safety, parse rather than source
  os_info = CSV.read(os_filename, col_sep: "=").to_h rescue {}

  os = os_info["ID"]
  os_version = os_info["VERSION_ID"]

  if os == "ubuntu" && os_version == "22.04" && !arm
    filename = "or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz"
    checksum = "a611133f4e9b75661c637347ebadff79539807cf8966eb9c176c2c560aad0a84"
  elsif os == "debian" && os_version == "11" && !arm
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "58c9f32d62031aa6679feb671758b3213fbc081ff46e7f850fef26aca2bd55ff"
  elsif os == "debian" && os_version == "11" && arm
    filename = "or-tools_arm64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "f308a06d89dce060f74e6fec4936b43f4bdf4874d18c131798697756200f4e7a"
  elsif os == "centos" && os_version == "7" && !arm
    filename = "or-tools_amd64_centos-7_cpp_v#{version}.tar.gz"
    checksum = "01715a3f6cd2b1f09b816061ced613eb7dc91524cc7c2268ce3faf783a9085ea"
  elsif os == "arch" && !arm
    filename = "or-tools_amd64_archlinux_cpp_v#{version}.tar.gz"
    checksum = "490e67af9f0dbf79b0dd24fc8c80631cd41bb1f94fceb5345d371426abf25897"
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
