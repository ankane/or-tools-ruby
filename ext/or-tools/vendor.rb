require "digest"
require "fileutils"
require "open-uri"
require "tmpdir"

version = "10.0-rc.1"

arch = RbConfig::CONFIG["host_cpu"]
arm = arch.match?(/arm|aarch64/i)

if RbConfig::CONFIG["host_os"].match?(/darwin/i)
  if arm
    filename = "ortools-arm64-macos-cpp.zip"
    checksum = "50cedc302339e5d07847fa1fbdef869356eb38484fbc0d7aded4f66c051175c7"
  else
    filename = "ortools-amd64-macos-cpp.zip"
    checksum = "cb97c75aad502f2f0ac62be628449a2edebaf1fe55cb8b06bb6662c9e8ebb0a9"
  end
elsif !Gem.win_platform?
  if arm
    filename = "ortools-arm64-linux-cpp.zip"
    checksum = "34ce9eb8dc31d3c209da672d3c22da21c1435dc2f3eb79bed550e395536ddb61"
  else
    filename = "ortools-amd64-linux-cpp.zip"
    checksum = "42e17d61cbe7a4cba03d8b826a32c0c17343652640f664f3f891f031c8622300"
  end
else
  # there is a binary download for Windows
  # however, it's compiled with Visual Studio rather than MinGW (which RubyInstaller uses)
  raise <<~MSG
    Binary installation not available for this platform: Windows

    Build the OR-Tools C++ library from source, then run:
    bundle config build.or-tools --with-or-tools-dir=/path/to/or-tools

  MSG
end

url = "https://github.com/google/or-tools/releases/download/v#{version}/#{filename}"

path = File.expand_path("../../tmp/or-tools", __dir__)
FileUtils.mkdir_p(path)

Dir.mktmpdir do |extract_path|
  # download
  puts "Downloading #{url}..."
  URI.parse(url).open(max_redirects: 10) do |download|
    download_checksum =
      if download.respond_to?(:path)
        download.flush
        Digest::SHA256.file(download.path).hexdigest
      else
        Digest::SHA256.hexdigest(download.string)
      end
    raise "Bad checksum: #{download_checksum}" if download_checksum != checksum

    # should never happen
    raise "Expected file" if !download.respond_to?(:path)

    Dir.mktmpdir do |unzip_path|
      system "unzip", "-q", download.path, "-d", unzip_path, exception: true

      # extract - can't use Gem::Package#extract_tar_gz from RubyGems
      # since it limits filenames to 100 characters (doesn't support UStar format)
      # for space, only keep licenses, include, and shared library
      tar_args = Gem.win_platform? ? ["--force-local"] : []
      # TODO fix version and name
      export_name = filename.include?("macos") ? "Darwin" : "Linux"
      system "tar", "zxf", "#{unzip_path}/export/OR-Tools-10.0.0-rc.1-#{export_name}.tar.gz", "-C", extract_path, "--strip-components=1", *tar_args, exception: true
    end
  end

  # include
  FileUtils.mv(File.join(extract_path, "include"), File.join(path, "include"))

  # shared library
  FileUtils.mkdir(File.join(path, "lib"))
  Dir.glob("lib/lib*{.dylib,.so,.so.*}", base: extract_path) do |file|
    next if file.include?("libprotoc.")
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end

  # licenses
  license_files = Dir.glob("**/*{LICENSE,LICENCE,NOTICE,COPYING,license,licence,notice,copying}*", base: extract_path)
  raise "License not found" unless license_files.any?
  license_files.each do |file|
    next if File.directory?(File.join(extract_path, file))
    FileUtils.mkdir_p(File.join(path, File.dirname(file)))
    FileUtils.mv(File.join(extract_path, file), File.join(path, file))
  end
end

# export
$vendor_path = path
