lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jekyll_test_harness/version'

Gem::Specification.new do |spec|
	spec.name = 'jekyll-test-harness'
	spec.version = JekyllTestHarness::VERSION
	spec.authors = ['Convincible']
	spec.email = ['development@convincible.media']

	spec.summary = 'Reusable integration test harness for Jekyll plugin development.'
	spec.description = 'Builds isolated temporary Jekyll sites for plugin RSpec and Minitest suites with optional framework helper DSL modules.'
	spec.homepage = 'https://github.com/ConvincibleMedia/jekyll-test-harness'
	spec.license = 'LGPL-3.0-or-later'

	spec.files = Dir.chdir(__dir__) { Dir['lib/**/*.rb'] + %w[readme.md CHANGELOG.md LICENSE.txt] }
	spec.require_paths = ['lib']

	spec.required_ruby_version = '>= 2.4.4'

	spec.add_dependency 'jekyll', '>= 3.8.5', '< 5.0'

	spec.add_development_dependency 'pry', '~> 0.13', '>= 0.13.1'
	spec.add_development_dependency 'pry-byebug', '~> 3.9', '>= 3.9.0'
	spec.add_development_dependency 'rspec', '~> 3.10'
end
