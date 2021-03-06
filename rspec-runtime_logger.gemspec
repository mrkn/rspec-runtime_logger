# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/runtime_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "rspec-runtime_logger"
  spec.version       = RSpec::RuntimeLogger::VERSION
  spec.authors       = ["Kenta Murata"]
  spec.email         = ["mrkn@cookpad.com"]
  spec.description   = %q{A formatter that records running times of spec files}
  spec.summary       = %q{A formatter that records running times of spec files}
  spec.homepage      = "https://github.com/mrkn/rspec-runntime_logger"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-core", "~> 2.14"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
