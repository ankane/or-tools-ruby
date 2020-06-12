require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "7.7.7810"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-10.15.5_v#{version}.tar.gz"
  checksum = "764f290f6d916bc366913a37d93e6f83bd7969ad33515ccc1ca390f544d65721"
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "309cad8a88cd86898d96821fa2049850481cbec420dfd85b65ad29e2bb5165b1"
  elsif os == "Ubuntu" && os_version == "16.04"
    filename = "or-tools_ubuntu-16.04_v#{version}.tar.gz"
    checksum = "90430a4f4848d67cf97f457256feeca8990ce6f5277abfd53c51ce6df0e214ae"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_debian-10_v#{version}.tar.gz "
    checksum = "b2dde80f4991b70e2a440f27508b10df20b1709efaa11205e85c327089cf8fdd"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_centos-8_v#{version}.tar.gz"
    checksum = "1481b2e0963cbfde02010e177be797aba8a2cb5fbc118037817e48c97a9e30e6"
  else
    # there is a binary download for Windows
    # however, it's compiled with Visual Studio rather than MinGW (which RubyInstaller uses)
    raise <<~MSG
      Binary installation not available for this platform.

      Build the OR-Tools C++ library from source, then run:
      bundle config build.or-tools --with-or-tools-dir=/path/to/or-tools

    MSG
  end
end

short_version = version.split(".").first(2).join(".")
url = "https://github.com/google/or-tools/releases/download/v#{short_version}/#{filename}"

$stdout.sync = true

def download_file(url, download_path)
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
  download_file(location, download_path) if location
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

# extract - can't use Gem::Package#extract_tar_gz from RubyGems
# since it limits filenames to 100 characters (doesn't support UStar format)
path = File.expand_path("../../tmp/or-tools", __dir__)
FileUtils.mkdir_p(path)
tar_args = Gem.win_platform? ? ["--force-local"] : []
system "tar", "zxf", download_path, "-C", path, "--strip-components=1", *tar_args

# export
$vendor_path = path
