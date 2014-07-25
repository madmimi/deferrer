# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deferrer/version'

Gem::Specification.new do |spec|
  spec.name          = "deferrer"
  spec.version       = Deferrer::VERSION
  spec.authors       = ["Dalibor Nasevic"]
  spec.email         = ["dalibor.nasevic@gmail.com"]
  spec.description   = %q{Defer work units and process only the last one}
  spec.summary       = %q{Defer work units and process only the last work unit when time comes}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
  spec.add_dependency "multi_json"
  spec.add_dependency "celluloid"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0.0"
end
