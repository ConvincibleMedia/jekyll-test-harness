# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::JekyllBlueprint do
	it 'deep-clones config and files so callers can mutate inputs safely' do
		config = { 'my_plugin' => { 'mode' => 'base' } }
		files = { 'index.md' => "---\nlayout: default\n---\nBody\n" }

		blueprint = described_class.new(config: config, files: files)
		config['my_plugin']['mode'] = 'changed'
		files['index.md'] = 'changed'

		expect(blueprint.config).to eq('my_plugin' => { 'mode' => 'base' })
		expect(blueprint.files).to include('index.md')
		expect(blueprint.files['index.md']).to include('Body')
	end

	it 'raises a clear error when config is not a hash' do
		expect do
			described_class.new(config: 'invalid', files: {})
		end.to raise_error(ArgumentError, /config must be a Hash/)
	end

	it 'raises a clear error when files is not a hash' do
		expect do
			described_class.new(config: {}, files: [])
		end.to raise_error(ArgumentError, /files must be a Hash/)
	end
end
