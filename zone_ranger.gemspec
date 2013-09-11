# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zone_ranger/version'

Gem::Specification.new do |spec|
  spec.name          = "zone_ranger"
  spec.version       = ZoneRanger::VERSION
  spec.authors       = ["Hubert Liu"]
  spec.email         = ["hubert.liu@rigor.com"]
  spec.description   = "Time Zone Ranger"
  spec.summary       = "Time Zone Ranger"
  spec.homepage      = "https://github.com/Rigor/zone_ranger"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop", "~> 0.3.5"

  spec.add_runtime_dependency "activesupport", "~> 3.0.20"
  spec.add_runtime_dependency 'i18n' # required by active_support
  spec.add_runtime_dependency 'tzinfo', '~> 0.3.35'
  #spec.add_runtime_dependency 'tzinfo-data'
end
