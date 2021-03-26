require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "8.2.8710"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-11.2.1_v#{version}.tar.gz"
  checksum = "1c3bd45ab10677aa96d404cb837067e786a6d98123d8b556cf29d6994aa43b3b"
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "20.04"
    filename = "or-tools_ubuntu-20.04_v#{version}.tar.gz"
    checksum = "ab3b3051b10a4bbe8d080857f3c4ef3cfe9c10896ff94f352bb779e993756dd7"
  elsif os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "0d052deb2ba4491c29e86242fb5d61d0fe14bac847c2feaa35fbeff925ea40a0"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_debian-10_v#{version}.tar.gz"
    checksum = "1f2ec99181c92859ab46e68a6231babce92ded949fd1d08ee31afa4db04c43b3"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_centos-8_v#{version}.tar.gz"
    checksum = "be638a20b36f6da81aa29fd24c69c4a66afc980b8a221b1cbabb3910b9827718"
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
