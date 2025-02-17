require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.12.4544"

arch = RbConfig::CONFIG["host_cpu"]
arm = arch.match?(/arm|aarch64/i)

if RbConfig::CONFIG["host_os"].match?(/darwin/i)
  if arm
    filename = "or-tools_arm64_macOS-15.3.1_cpp_v#{version}.tar.gz"
    checksum = "02f89e54bd8d86e6e069f843aeed10a444ff329052e5a7fd732c5e4ec4f845fb"
  else
    filename = "or-tools_x86_64_macOS-15.3.1_cpp_v#{version}.tar.gz"
    checksum = "515af60e73e7fa620bab7f4a7d60b9069075d814453d91906aa39993d714f28d"
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
    checksum = "71128e095024707bf9835faf4558cbe34acb79345e899bd532f3008a493a8970"
  elsif os == "ubuntu" && os_version == "22.04" && !arm
    filename = "or-tools_amd64_ubuntu-22.04_cpp_v#{version}.tar.gz"
    checksum = "cb42ea7d7799a01fea7cdaafacbdfc67180d85f39532c6d2a8c4cfb419bd07ed"
  elsif os == "ubuntu" && os_version == "20.04" && !arm
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "ea51589fe80bd9cd4fb6203bd1e956b311cdb1d21bbd14f7b6dad75c81d3583c"
  elsif os == "debian" && os_version == "11" && !arm
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "dcee63b726569bd99c134e0e920173f955feae5856c3370a0bed03fdc995af50"
  elsif os == "debian" && os_version == "12" && !arm
    filename = "or-tools_amd64_debian-12_cpp_v#{version}.tar.gz"
    checksum = "911143f50fe013fbd50d0dce460512106596adfc0f2ad9a2bc8afd218531bde4"
  elsif os == "fedora" && os_version == "41" && !arm
    filename = "or-tools_amd64_fedora-41_cpp_v#{version}.tar.gz"
    checksum = "44e3ea31924ae1893a669c4ccf46b5efaf2d37157c0417a9b8038568e9e7c1fb"
  elsif os == "fedora" && os_version == "40" && !arm
    filename = "or-tools_amd64_fedora-40_cpp_v#{version}.tar.gz"
    checksum = "ba595e2a9c86e23f559d1be17984ab4cfe56599bb0decd1f5e5b6c4008464023"
  elsif os == "arch" && !arm
    filename = "or-tools_amd64_archlinux_cpp_v#{version}.tar.gz"
    checksum = "18c1d929e2144e9d9602659ea2fa790bd2a150f72c32c38a97f571839816d132"
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
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end

  # include
  FileUtils.mv(File.join(extract_path, "include"), File.join(path, "include"))

  # shared library
  FileUtils.mkdir(File.join(path, "lib"))
  Dir.glob("{lib,lib64}/lib*{.dylib,.so,.so.*}", base: extract_path) do |file|
    next if file.include?("libprotoc.")
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end
end

# export
$vendor_path = path
