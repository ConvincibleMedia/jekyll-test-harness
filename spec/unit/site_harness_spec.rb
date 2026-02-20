# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::SiteHarness do
	describe '.merge_data' do
		it 'deep-merges nested hashes while replacing arrays and scalar values' do
			base = {
				'a' => {
					'b' => 1,
					'list' => [1, 2],
					'nested' => { 'x' => 'left' }
				},
				'keep' => true
			}
			overrides = {
				'a' => {
					'b' => 2,
					'list' => ['replaced'],
					'nested' => { 'y' => 'right' }
				},
				'new' => 'value'
			}

			merged = described_class.merge_data(base, overrides)

			expect(merged).to eq(
				'a' => {
					'b' => 2,
					'list' => ['replaced'],
					'nested' => { 'x' => 'left', 'y' => 'right' }
				},
				'keep' => true,
				'new' => 'value'
			)
		end

		it 'handles nil values by returning a deep clone of the non-nil input' do
			base = { 'a' => { 'b' => 1 } }
			merged_from_nil_base = described_class.merge_data(nil, base)
			merged_from_nil_overrides = described_class.merge_data(base, nil)

			expect(merged_from_nil_base).to eq(base)
			expect(merged_from_nil_overrides).to eq(base)
			expect(merged_from_nil_base).not_to equal(base)
			expect(merged_from_nil_overrides).not_to equal(base)
		end
	end

	describe '.with_site' do
		it 'raises a harness-specific error when no block is supplied' do
			expect do
				described_class.with_site
			end.to raise_error(Jekyll::TestHarness::MissingBlockError)
		end

		it 'writes default scaffold files by default' do
			described_class.with_site do |_site, paths|
				expect(paths.read_source('_layouts/default.html')).to include('{{ content }}')
				expect(paths.read_source('index.md')).to include('Hello from the Jekyll test harness default scaffold.')
			end
		end

		it 'allows callers to disable default scaffold generation' do
			described_class.with_site(default_scaffold: false, files: { 'index.md' => "---\n---\nCustom index\n" }) do |_site, paths|
				expect(File.exist?(paths.source_path('_layouts/default.html'))).to be(false)
				expect(paths.read_source('index.md')).to include('Custom index')
			end
		end
	end
end
