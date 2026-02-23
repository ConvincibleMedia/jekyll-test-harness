# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::DataTools do
	describe '.deep_clone' do
		it 'deep-clones nested hashes, arrays, and strings' do
			original = {
				'config' => {
					'items' => ['alpha', { 'nested' => 'beta' }]
				}
			}

			cloned = described_class.deep_clone(original)
			cloned['config']['items'][0].replace('changed')
			cloned['config']['items'][1]['nested'].replace('changed')

			expect(original).to eq(
				'config' => {
					'items' => ['alpha', { 'nested' => 'beta' }]
				}
			)
		end

		it 'returns immutable scalar objects unchanged' do
			value = :symbol_value
			expect(described_class.deep_clone(value)).to equal(value)
			expect(described_class.deep_clone(42)).to eq(42)
		end
	end

	describe '.deep_merge_hashes' do
		it 'deep-merges nested hashes while replacing scalar and array values' do
			base_hash = {
				'a' => { 'nested' => { 'left' => true }, 'list' => [1, 2] },
				'b' => 'base'
			}
			new_hash = {
				'a' => { 'nested' => { 'right' => true }, 'list' => ['replaced'] },
				'c' => 'new'
			}

			merged_hash = described_class.deep_merge_hashes(base_hash, new_hash)

			expect(merged_hash).to eq(
				'a' => { 'nested' => { 'left' => true, 'right' => true }, 'list' => ['replaced'] },
				'b' => 'base',
				'c' => 'new'
			)
		end

		it 'does not mutate either input hash' do
			base_hash = { 'a' => { 'b' => 'base' } }
			new_hash = { 'a' => { 'c' => 'new' } }
			base_snapshot = Marshal.load(Marshal.dump(base_hash))
			new_snapshot = Marshal.load(Marshal.dump(new_hash))

			described_class.deep_merge_hashes(base_hash, new_hash)

			expect(base_hash).to eq(base_snapshot)
			expect(new_hash).to eq(new_snapshot)
		end

		it 'raises a clear error when either input is not a hash' do
			expect do
				described_class.deep_merge_hashes([], {})
			end.to raise_error(ArgumentError, /must both be Hash values/)

			expect do
				described_class.deep_merge_hashes({}, nil)
			end.to raise_error(ArgumentError, /must both be Hash values/)
		end
	end
end
