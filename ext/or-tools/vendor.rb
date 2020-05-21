require "digest"
require "fileutils"
require "net/http"
require "rubygems/package"
require "tmpdir"

version = "7.6.7691"

if Gem.win_platform?
  abort "Not supported yet"
elsif RbConfig::CONFIG["host_os"] =~ /darwin/i
  filename = "or-tools_MacOsX-10.15.4_v#{version}.tar.gz"
  dirname = "or-tools_MacOsX-10.15.4_v#{version}"
  checksum = "39e26ba27b4d3a1c194c1478e864cd016d62cf516cd9227a9f23e6143e131572"
else
  # TODO detect platform
  filename = "or-tools_ubuntu-18.04_v#{version}.tar.gz"
  dirname = "or-tools_Ubuntu-18.04-64bit_v#{version}"
  checksum = "79ef61dfc63b98133ed637f02e837f714a95987424332e511a3a87edd5ce17dc"
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
        digest = Digest::SHA2.new

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
        abort "Bad response"
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
abort "Bad checksum: #{download_checksum}" if download_checksum != checksum

# extract
path = File.expand_path("../../tmp", __dir__)
FileUtils.mkdir_p(path)
File.open(download_path, "rb") do |io|
  Gem::Package.new("").extract_tar_gz(io, path)
end

# export
$vendor_path = "#{path}/#{dirname}"
