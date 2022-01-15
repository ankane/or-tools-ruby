require "digest"
require "fileutils"
require "net/http"
require "tmpdir"

version = "9.2.9972"

if RbConfig::CONFIG["host_os"] =~ /darwin/i
  if RbConfig::CONFIG["host_cpu"] =~ /arm|aarch64/i
    raise <<~MSG
      Binary installation not available for this platform: Mac ARM

      Run:
      brew install or-tools
      bundle config build.or-tools --with-or-tools-dir=/opt/homebrew

    MSG
  else
    filename = "or-tools_MacOsX-12.0.1_v#{version}.tar.gz"
    checksum = "796791a8ef84507d62e193e647cccb1c7725dae4f1474476e1777fe4a44ee3e0"
  end
else
  os = %x[lsb_release -is].chomp rescue nil
  os_version = %x[lsb_release -rs].chomp rescue nil
  if os == "Ubuntu" && os_version == "20.04"
    filename = "or-tools_amd64_ubuntu-20.04_v#{version}.tar.gz"
    checksum = "985e3036eaecacfc8a0258ec2ebef429240491577d4e0896d68fc076e65451ec"
  elsif os == "Ubuntu" && os_version == "18.04"
    filename = "or-tools_amd64_ubuntu-18.04_v#{version}.tar.gz"
    checksum = "e36406c4fe8c111e1ace0ede9d0787ff0e98f11afd7db9cc074adfd0f55628a6"
  elsif os == "Debian" && os_version == "11"
    filename = "or-tools_amd64_debian-11_v#{version}.tar.gz"
    checksum = "bd49ee916213b2140ab255414d35a28f19dff7caf87632309753d3fc553f85dd"
  elsif os == "Debian" && os_version == "10"
    filename = "or-tools_amd64_debian-10_v#{version}.tar.gz"
    checksum = "b152fee584f0c8228fe2ff21b74c789870ff9b7064e42ca26305c6b5653f0064"
  elsif os == "CentOS" && os_version == "8"
    filename = "or-tools_amd64_centos-8_v#{version}.tar.gz"
    checksum = "66ed4bb800acf92c672f7e68acdf4ea27bbfdb17bbddc02f8326cd55a97305f6"
  elsif os == "CentOS" && os_version == "7"
    filename = "or-tools_amd64_centos-7_v#{version}.tar.gz"
    checksum = "4a5c1b1639a2828cd7e1ba82a574ef37876557b59e8aab8b81811bb750d53035"
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
