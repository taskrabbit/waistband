# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'waistband/version'

Gem::Specification.new do |spec|
  spec.name          = "waistband"
  spec.version       = Waistband::VERSION
  spec.authors       = ["David Jairala"]
  spec.email         = ["davidjairala@gmail.com"]
  spec.description   = %q{Ruby interface to Elastic Search}
  spec.summary       = %q{Elastic Search all the things!}
  spec.homepage      = "https://github.com/taskrabbit/waistband"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport',  '>= 3.0.0'
  spec.add_dependency 'rest-client',    '~> 1.6.7'

  spec.add_development_dependency "bundler", "~> 1.2.3"
  spec.add_development_dependency "rake"
end
