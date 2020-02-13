require_relative "lib/or_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "or-tools"
  spec.version       = ORTools::VERSION
  spec.summary       = "Operations research tools for Ruby"
  spec.homepage      = "https://github.com/ankane/or-tools"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@chartkick.com"

  spec.files         = Dir["*.{md,txt}", "{lib,ext}/**/*"]
  spec.require_path  = "lib"
  spec.extensions    = ["ext/or-tools/extconf.rb"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "rice", ">= 2.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "minitest", ">= 5"
end
