require "csv"
require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.6.2534"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if RbConfig::CONFIG["host_cpu"] =~ /arm|aarch64/i
    filename = "or-tools_arm64_macOS-13.2.1_cpp_v#{version}.tar.gz"
    checksum = "bb82c3b071e8ea5366a52137f400b280120221611758e38bf3d55c819f81c34b"
  else
    filename = "or-tools_x86_64_macOS-13.2.1_cpp_v#{version}.tar.gz"
    checksum = "0957ed39792d5f6135edf86ed75e78fff5b2f36ec0ae63e30c46bd6a6a97797f"
  end
else
  # try /etc/os-release with fallback to /usr/lib/os-release
  # https://www.freedesktop.org/software/systemd/man/os-release.html
  os_filename = File.exist?("/etc/os-release") ? "/etc/os-release" : "/usr/lib/os-release"

  # for safety, parse rather than source
  os_info = CSV.read(os_filename, col_sep: "=").to_h rescue {}

  os = os_info["ID"]
  os_version = os_info["VERSION_ID"]

  if os == "ubuntu" && os_version == "22.04"
    filename = "or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz"
    checksum = "e7960113b156b13e23a179ca09646845e762f452aa525bf9b12a40e5ae3c6ca4"
  elsif os == "ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "aff9714ee8ffd1c936024d6a754f697cf80d4fd5aafa4cf121a4dde114f3813f"
  elsif os == "ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_cpp_v#{version}.tar.gz"
    checksum = "467713721be3fdc709cc7fd0c8d6ad99dda73cab1b9c5de3568336c6ebef6473"
  elsif os == "debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "4191e3e910156d6e9d6e69fb9ab6ed57c683f018b218b46cce91c7ece6549dc6"
  elsif os == "debian" && os_version == "10"
    filename = "or-tools_amd64_debian-10_cpp_v#{version}.tar.gz"
    checksum = "f141f16cf92877ed5819e0104126a31c9c139c070de06d7f40c957a4e6ce9284"
  elsif os == "centos" && os_version == "8"
    filename = "or-tools_amd64_centos-8_cpp_v#{version}.tar.gz"
    checksum = "05e2dfc5c82d5122e0c26ce4548cddcae2d474b3b18c024bc189dab887357157"
  elsif os == "centos" && os_version == "7"
    filename = "or-tools_amd64_centos-7_cpp_v#{version}.tar.gz"
    checksum = "96012ac1280a98d6a67e764494bf60971eece859dca95fb6470ffd4065af7444"
  else
    platform =
      if Gem.win_platform?
        "Windows"
      elsif os || os_version
        "#{os} #{os_version}"
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
end

# export
$vendor_path = path
