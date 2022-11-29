require "csv"
require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.5.2237"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if RbConfig::CONFIG["host_cpu"] =~ /arm|aarch64/i
    filename = "or-tools_arm64_macOS-13.0.1_cpp_v#{version}.tar.gz"
    checksum = "9041ccb29618bce793c68eaa30a01b1fbaa6491656bddd942753d9a412544db7"
  else
    filename = "or-tools_x86_64_macOS-13.0.1_cpp_v#{version}.tar.gz"
    checksum = "f4af2bfd3b19cff6056e01abcddf1f5a54a0da891cafd73a25a671a3abd17c76"
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
    checksum = "acecd79867f4bd5f6b91d95743fc858e939d8611e534914a540ee4f46c535247"
  elsif os == "ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "506b420e1b1232440e49680e55ae087000f2c92b1009e46417c774d8332f217b"
  elsif os == "ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_cpp_v#{version}.tar.gz"
    checksum = "96ee5b4f3cf6dfece6dc54a78c6aa4a55dae5bd7d4f4176b332d3f3aa6cd973f"
  elsif os == "debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "00bef600d0e2452544484f26f49bada4f717d7735f9d65c3961def8ab83876d3"
  elsif os == "debian" && os_version == "10"
    filename = "or-tools_amd64_debian-10_cpp_v#{version}.tar.gz"
    checksum = "a45c566dbfe818386bc1aa061a167650c691f447b2937cdc8bdb1e9054ba4715"
  elsif os == "centos" && os_version == "8"
    filename = "or-tools_amd64_centos-8_cpp_v#{version}.tar.gz"
    checksum = "af82328d06c402917735482045e7abc37a6f9258db3d607d6efc62c27f765334"
  elsif os == "centos" && os_version == "7"
    filename = "or-tools_amd64_centos-7_cpp_v#{version}.tar.gz"
    checksum = "3d28bdd3ab27224b80960393c7f51e7c228ae78297c28e4ae79bc6c269ae44fe"
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
