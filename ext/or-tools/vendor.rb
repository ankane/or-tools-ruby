require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.1.9490"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-11.6_v#{version}.tar.gz"
  checksum = "97a2b113806c1b2d17f9b3f30571c9ee82722eb22e06bd124d94118f3a84da2c"
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_v#{version}.tar.gz"
    checksum = "cf82e5c343ab74bef320b240a2c3937b07df945e60b91bbc771b477c0856c1bd"
  elsif os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "b641677cc3e1095b7e8efd9c5c948698f5e2c238d10d06f1abf0b0ee240addf2"
  elsif os == "Debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_v#{version}.tar.gz"
    checksum = "de7e63988fc62c64718d8f8f37f98a1c589c89ebc46fc1f378da4b66ad385ff1"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_amd64_debian-10_v#{version}.tar.gz"
    checksum = "80411caeccac079fe8ee6018ceae844f5f04d2deecacd3406d51354dea5435e4"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_amd64_centos-8_v#{version}.tar.gz"
    checksum = "fe23b04dd7a20c5902fbf89bb626080296489a05e0bfb39225e71be5e9cee1ac"
  elsif os == "CentOS" && os_version == "7"
    filename = "or-tools_amd64_centos-7_v#{version}.tar.gz"
    checksum = "ef48363b27591c25f8702e085024aa7b5f5190ad94c859481116538f04c124f9"
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

# extract - can't use Gem::Package#extract_tar_gz from RubyGems
# since it limits filenames to 100 characters (doesn't support UStar format)
path = File.expand_path("../../tmp/or-tools", __dir__)
FileUtils.mkdir_p(path)
tar_args = Gem.win_platform? ? ["--force-local"] : []
system "tar", "zxf", download_path, "-C", path, "--strip-components=1", *tar_args

# export
$vendor_path = path
