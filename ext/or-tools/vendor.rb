require "csv"
require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.4.1874"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if RbConfig::CONFIG["host_cpu"] =~ /arm|aarch64/i
    filename = "or-tools_arm64_MacOsX-12.5_cpp_v#{version}.tar.gz"
    checksum = "ebc185bcb0a056a2704fb1c5175d5c11cc21a7e0634be65139cea55bb6a021ce"
  else
    filename = "or-tools_x86_64_MacOsX-12.5_cpp_v#{version}.tar.gz"
    checksum = "d03c706b51a6ef7aa77886dc3f135baaac52c00803bb548c286fbdeb4a419acd"
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
    checksum = "d7e222fc4f30c9864bfa3062accc8b4dd291c3166ba9cf3576c6c86eded71940"
  elsif os == "ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_cpp_v#{version}.tar.gz"
    checksum = "1b09f0f60b5aab83aeec468842e4a166cd3a4e7910e807f55bc7f96d5dffabdb"
  elsif os == "ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_cpp_v#{version}.tar.gz"
    checksum = "ef73ebd4ca0f82a1179fdb2aded3c2a85dfe2ab275d91b8a5b147a653ca861ab"
  elsif os == "debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_cpp_v#{version}.tar.gz"
    checksum = "651c62147f231fb90635c522e0a2c799e3de3991c2c75f7c6acb721e7b78946c"
  elsif os == "debian" && os_version == "10"
    filename = "or-tools_amd64_debian-10_cpp_v#{version}.tar.gz"
    checksum = "36088bc6c6fbb96539245db7cddf498f77ae3e7b7c2cc8f6d7d89d76f90751fb"
  elsif os == "centos" && os_version == "8"
    filename = "or-tools_amd64_centos-8_cpp_v#{version}.tar.gz"
    checksum = "da2cb303ae332d207592f21bb504e4e2e33dc1b1e8f5747d413c082d9d05504a"
  elsif os == "centos" && os_version == "7"
    filename = "or-tools_amd64_centos-7_cpp_v#{version}.tar.gz"
    checksum = "9eaf0178467f4d2fdbe496f62223809aa43e313548cc6cb716e661c00472b4ff"
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
