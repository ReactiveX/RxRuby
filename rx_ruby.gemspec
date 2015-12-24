# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rx_ruby/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Microsoft Open Technologies, Inc."]
  gem.description   = %q{Reactive Extensions for Ruby}
  gem.summary       = %q{This is an implementation of the Reactive Extensions for Ruby. Note that this is an early prototype, but contributions are welcome.}
  gem.homepage      = "https://github.com/ReactiveX/RxRuby"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rx_ruby"
  gem.require_paths = ["lib"]
  gem.version       = RxRuby::VERSION
  gem.license       = 'Apache License, v2.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'simplecov'
end
