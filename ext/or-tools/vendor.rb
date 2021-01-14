require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "8.1.8487"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-10.15.7_v#{version}.tar.gz"
  checksum = "cdf5d5c4dd10ddfa39eb951e6b8122b2a48c7d1dbd87bb5f792a7596aea8b8bb"
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "20.04"
    filename = "or-tools_ubuntu-20.04_v#{version}.tar.gz"
    checksum = "2de596d649d9a0f0dfec8007d6e1018d8fdddced7aa340b4e68d02e61df89a2e"
  elsif os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "201cf1d17379240311208f4c641bb5263ae19d8c4c1a6091d2778948fd375f48"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_debian-10_v#{version}.tar.gz "
    checksum = "18028ef7287cd83eed3dafeae1243a9adb445675f45984e8d3c60ab9e2aa75bd"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_centos-8_v#{version}.tar.gz"
    checksum = "e26229320f9b78315f0122b55d16093c79e2dc6c95d591f4788f323f27cfd3bf"
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
