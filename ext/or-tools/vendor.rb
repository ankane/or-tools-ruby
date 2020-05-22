require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "7.6.7691"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-10.15.4_v#{version}.tar.gz"
  checksum = "39e26ba27b4d3a1c194c1478e864cd016d62cf516cd9227a9f23e6143e131572"
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "79ef61dfc63b98133ed637f02e837f714a95987424332e511a3a87edd5ce17dc"
  elsif os == "Ubuntu" && os_version == "16.04"
    filename = "or-tools_ubuntu-16.04_v#{version}.tar.gz"
    checksum = "a25fc94c0f0d16abf1f6da2a054040c21ef3cbf618a831a15afe21bf14f2d1fb"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_debian-10_v#{version}.tar.gz "
    checksum = "158c44038aebc42b42b98e8f3733ba83bf230e8a0379803cc48aafbb2f7bdf5a"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_centos-8_v#{version}.tar.gz"
    checksum = "a2b800d4e498561e5b1fe95ee1e64c867be496038883f4f7b199499bf71a0eed"
  else
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

# check integrity
download_checksum = Digest::SHA256.file(download_path).hexdigest
raise "Bad checksum: #{download_checksum}" if download_checksum != checksum

# extract - can't use Gem::Package#extract_tar_gz from RubyGems since it limits path to 100 characters
path = File.expand_path("../../tmp/or-tools", __dir__)
FileUtils.mkdir_p(path)
tar_args = Gem.win_platform? ? ["--force-local"] : []
system "tar", "zxf", download_path, "-C", path, "--strip-components=1", *tar_args

# export
$vendor_path = path
