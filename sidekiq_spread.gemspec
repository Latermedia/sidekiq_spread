# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq_spread/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq_spread'
  spec.version       = SidekiqSpread::VERSION
  spec.authors       = ['Les Fletcher']
  spec.email         = ['les@later.com']

  spec.summary       = "Add 'perform_spread' method to workers to allow for scheduling jobs over an interval of time."
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/Latermedia/sidekiq_spread'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency('sidekiq')

  spec.add_development_dependency 'activesupport', '> 3.0'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'fakeredis'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  spec.add_development_dependency 'rubocop', '0.60.0'
  spec.add_development_dependency 'yard'
end
