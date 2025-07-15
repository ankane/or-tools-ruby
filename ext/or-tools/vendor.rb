require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.14.6206"

arch = RbConfig::CONFIG["host_cpu"]
arm = arch.match?(/arm|aarch64/i)

if RbConfig::CONFIG["host_os"].match?(/darwin/i)
  if arm
    filename = "or-tools_arm64_macOS-15.5_cpp_v#{version}.tar.gz"
    checksum = "7dd3fc35acc74a85f44e39099dcc2caa698d7a99e659e8d8456ce25bafe4a63b"
  else
    filename = "or-tools_x86_64_macOS-15.5_cpp_v#{version}.tar.gz"
    checksum = "de7ed91b0fe90094fb5f5ebd19869b69a8d52b9752e456752208a22a05b14f7f"
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
    checksum = "be3855a32a7390c3957d43ebd3faec1610acdc28f06ef33cb50f1f72a9aa6621"
  elsif os == "ubuntu" && os_version == "22.04" && !arm
    filename = "or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz"
    checksum = "127a82bbbf304d26721bb9b41ecce2d66f21c757204ab5aa2cc37eaa6ffb7eb6"
  elsif os == "ubuntu" && os_version == "20.04" && !arm
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "7705a7c11e0db4ec1d7841e184acd204787174c6cbdb2fbd81169823ed148c6c"
  elsif os == "debian" && os_version == "12" && !arm
    filename = "or-tools_amd64_debian-12_cpp_v#{version}.tar.gz"
    checksum = "285e8ec3a3399e45cdb4f67f48d4b65dbfa9c013b29036d409c72f96f0f34ab9"
  elsif os == "debian" && os_version == "11" && !arm
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "646b53e8d355290c4627d6bad0d36baeff38dc43605d317ac02cb811688d4dd2"
  elsif os == "arch" && !arm
    filename = "or-tools_amd64_archlinux_cpp_v#{version}.tar.gz"
    checksum = "6be039a13c3be7a3dbcdc413d455b43bba4590ce38859062898835effefb5ca4"
  elsif os == "fedora" && os_version == "42" && !arm
    filename = "or-tools_amd64_fedora-42_cpp_v#{version}.tar.gz"
    checksum = "d1c3a890528875dcd3a435077a8f75bf6ae31b769b2d4a0463a6f21d57256aae"
  elsif os == "fedora" && os_version == "41" && !arm
    filename = "or-tools_amd64_fedora-41_cpp_v#{version}.tar.gz"
    checksum = "81f84cf618dc8690a7184e797fa183afb075c7f50e9fa7cb5858f27fafe2db4b"
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

  # include
  FileUtils.mv(File.join(extract_path, "include"), File.join(path, "include"))

  # shared library
  FileUtils.mkdir(File.join(path, "lib"))
  Dir.glob("{lib,lib64}/lib*{.dylib,.so,.so.*}", base: extract_path) do |file|
    next if file.include?("libprotoc.")
    FileUtils.mv(File.join(extract_path, file), File.join(path, file.sub(/\Alib64/, "lib")))
  end

  # licenses
  license_files = Dir.glob("**/*{LICENSE,LICENCE,NOTICE,COPYING,license,licence,notice,copying}*", base: extract_path)
  raise "License not found" unless license_files.any?
  license_files.each do |file|
    FileUtils.mkdir_p(File.join(path, File.dirname(file)))
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end
end

# export
$vendor_path = path
