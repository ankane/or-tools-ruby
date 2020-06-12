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
    checksum = "12bdac29144b077b3f9ba602f947e4b9b9ce63ed3df4e325cda1333827edbcf8"
  elsif os == "Ubuntu" && os_version == "16.04"
    filename = "or-tools_ubuntu-16.04_v#{version}.tar.gz"
    checksum = "cc696d342b97aa6cf7c62b6ae2cae95dfc665f2483d147c4117fdba434b13a53"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_debian-10_v#{version}.tar.gz "
    checksum = "3dd0299e9ad8d12fe6d186bfd59e63080c8e9f3c6b0489af9900c389cf7e4224"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_centos-8_v#{version}.tar.gz"
    checksum = "1f7d8bce56807c4283374e05024ffac8afd81ff99063217418d02d626cf03088"
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
