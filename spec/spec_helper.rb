# frozen_string_literal: true

require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'rspec'

require 'jekyll_test_harness'
require 'jekyll_test_harness/rspec'

Dir[File.join(__dir__, 'fixtures', 'plugins', '*.rb')].sort.each { |fixture_file| require fixture_file }

RSpec.configure do |config|
	# Makes the harness DSL available in all specs.
	Jekyll::TestHarness::RSpec.configure(config)
end
