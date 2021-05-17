require_relative "lib/or_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "or-tools"
  spec.version       = ORTools::VERSION
  spec.summary       = "Operations research tools for Ruby"
  spec.homepage      = "https://github.com/ankane/or-tools"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib,ext}/**/*"]
  spec.require_path  = "lib"
  spec.extensions    = ["ext/or-tools/extconf.rb"]

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "rice", ">= 4.0.2"
end
