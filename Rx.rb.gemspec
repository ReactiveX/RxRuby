# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Microsoft Corporation"]
  gem.description   = %q{Reactive Extensions for Ruby}
  gem.summary       = %q{This is an implementation of the Reactive Extensions for Ruby. Note that this is an early prototype, but contributions are welcome.}
  gem.homepage      = "https://github.com/Reactive-Extensions/Rx.rb"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "Rx.rb"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
