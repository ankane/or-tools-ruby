require "csv"
require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.3.10497"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if RbConfig::CONFIG["host_cpu"] =~ /arm|aarch64/i
    raise <<~MSG
      Binary installation not available for this platform: Mac ARM

      Run:
      brew install or-tools
      bundle config build.or-tools --with-or-tools-dir=/opt/homebrew

    MSG
  else
    filename = "or-tools_MacOsX-12.2.1_v#{version}.tar.gz"
    checksum = "33941702c59983897935eef06d91aca6c89ed9a8f5f4de3a9dfe489e97d7ca8c"
  end
else
  # try /etc/os-release with fallback to /usr/lib/os-release
  # https://www.freedesktop.org/software/systemd/man/os-release.html
  os_filename = File.exist?("/etc/os-release") ? "/etc/os-release" : "/usr/lib/os-release"

  # for safety, parse rather than source
  os_info = CSV.read(os_filename, col_sep: "=").to_h rescue {}

  os = os_info["ID"]
  os_version = os_info["VERSION_ID"]

  if os == "ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_v#{version}.tar.gz"
    checksum = "91c3c4565c2e337f48696a3f578193912f1abefd62bc7b69e03daf1fe4f4df88"
  elsif os == "ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "6ba5cc153417267e8f8e15f8b6390b17f22de07bacc61f3740a4172ccd56c274"
  elsif os == "debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_v#{version}.tar.gz"
    checksum = "db0636bab909eabf06a7004f7572dca6fa152f3823c1365b0b7428405bf250e6"
  elsif os == "centos" && os_version == "8"
    filename = "or-tools_amd64_centos-8_v#{version}.tar.gz"
    checksum = "e5649069fd7a3e8228cc18b91e265a90562c5d03a0c962b0346911aada0aedc9"
  elsif os == "centos" && os_version == "7"
    filename = "or-tools_amd64_centos-7_v#{version}.tar.gz"
    checksum = "3bffdec8c09fc1345dcbd6a553437e2894014093fafb53e50adc7d4d776bb08b"
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
  Dir.glob("lib/libortools.{dylib,so.9}", base: extract_path) do |file|
    FileUtils.cp(File.join(extract_path, file), File.join(path, file))
  end
  File.symlink(File.join(path, "lib/libortools.so.9"), File.join(path, "lib/libortools.so"))
end

# export
$vendor_path = path
