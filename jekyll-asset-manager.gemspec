lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jekyll/test_harness/version'

Gem::Specification.new do |spec|
	spec.name = 'jekyll-test-harness'
	spec.version = Jekyll::TestHarness::VERSION
	spec.authors = ['Convincible']
	spec.email = ['development@convincible.media']

	spec.summary = 'Reusable integration test harness for Jekyll plugin development.'
	spec.description = 'Builds isolated temporary Jekyll sites for plugin RSpec suites and exposes optional RSpec helper DSL.'
	spec.homepage = 'https://github.com/ConvincibleMedia/jekyll-test-harness'
	spec.license = 'LGPL-3.0-or-later'

	spec.files = Dir['lib/**/*.rb'] + %w[readme.md]

	spec.required_ruby_version = '>= 2.5.0'

	spec.add_dependency 'jekyll', '>= 3.8', '< 5.0'

	spec.add_development_dependency 'bundler', '>= 2.4', '< 5.0'
	spec.add_development_dependency 'pry', '~> 0.14'
	spec.add_development_dependency 'pry-byebug', '~> 3.10'
	spec.add_development_dependency 'rspec', '~> 3.13'
end
