# frozen_string_literal: true

require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'rspec'

require 'jekyll_test_harness'

Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |support_file| require support_file }
Dir[File.join(__dir__, 'fixtures', 'plugins', '*.rb')].sort.each { |fixture_file| require fixture_file }

RSpec.configure do |config|
	# Makes the harness DSL available in all specs.
	JekyllTestHarness.install!(framework: :rspec)
end

