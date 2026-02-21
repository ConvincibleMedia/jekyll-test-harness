# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::Configuration do
	describe '.default_config' do
		it 'provides deterministic baseline keys and values' do
			config = described_class.default_config(source: '/tmp/source', destination: '/tmp/destination')

			expect(config).to eq(
				'source' => '/tmp/source',
				'destination' => '/tmp/destination',
				'quiet' => true,
				'incremental' => false
			)
		end
	end

	describe '.default_scaffold_files' do
		it 'returns a deep clone on every call' do
			first = described_class.default_scaffold_files
			second = described_class.default_scaffold_files

			first['_layouts']['default.html'].replace('changed')
			first['index.md'].replace('changed')

			expect(second['_layouts']['default.html']).to include('{{ content }}')
			expect(second['index.md']).to include('Hello from the Jekyll test harness default scaffold.')
		end
	end

	describe '.temporary_directory_prefix' do
		it 'returns the shared prefix used for temporary site directories' do
			expect(described_class.temporary_directory_prefix).to eq('jekyll-test-harness-')
		end
	end
end
