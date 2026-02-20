# frozen_string_literal: true

require 'bundler/setup'
require 'rspec'
require 'jekyll'
require 'jekyll-asset_manager'

support_root = File.expand_path(__dir__)
Dir[File.join(support_root, 'jekyll', '**', '*.rb')].sort.each { |file| require file }
require File.join(support_root, 'asset_manager_support')

RSpec.configure do |config|
	# Ensures each example starts with a fresh AssetDB instance.
	config.before do
		Jekyll::Plugins::AssetManager.db = nil
	end

	# Makes Asset Manager fixtures and helpers available to specs.
	config.include AssetManagerSpecSupport::Fixtures
	config.include AssetManagerSpecSupport::Helpers
end
