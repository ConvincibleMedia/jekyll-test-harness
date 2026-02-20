lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
	spec.name        = 'jekyll-test-harness'
	spec.version     = '0.1.0'
	spec.authors     = ["Convincible"]
	spec.email       = ["development@convincible.media"]

	spec.summary     = "Testing framework for Jekyll plugins."
	spec.description = "Builds a real Jekyll site with your plugin to fully test it."
	spec.homepage    = "https://github.com/ConvincibleMedia/jekyll-test-harness"
	spec.license     = "LGPL-3.0-or-later"

	spec.files       = Dir['lib/**/*.rb']

	spec.required_ruby_version = ">= 2.5.0"

	# Dependencies
	#spec.add_dependency 'kramdown', '~> 2.3'
	spec.add_dependency "jekyll", ">= 3.8", "< 5.0"
	spec.add_dependency "rspec", "~> 3.13"

	# Development dependencies
	spec.add_development_dependency "bundler", "~> 4.0"
	spec.add_development_dependency "pry", "~> 0.14"
	spec.add_development_dependency "pry-byebug", "~> 3.10"
end
