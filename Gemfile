source "https://rubygems.org"

gemspec

gem "rake"
gem "rake-compiler"
gem "minitest"
gem "ruby_memcheck", require: false

# https://github.com/ruby/openssl/issues/952
gem "openssl" if RUBY_PLATFORM =~ /darwin/
