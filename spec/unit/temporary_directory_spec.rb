# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::TemporaryDirectory do
	it 'raises a harness-specific error when no block is supplied' do
		expect do
			described_class.with_dir
		end.to raise_error(Jekyll::TestHarness::MissingBlockError)
	end

	it 'removes the temporary directory after successful execution' do
		temporary_directory_path = nil

		described_class.with_dir do |directory|
			temporary_directory_path = directory
			File.write(File.join(directory, 'sentinel.txt'), 'ok')
			expect(File.exist?(File.join(directory, 'sentinel.txt'))).to be(true)
		end

		expect(Dir.exist?(temporary_directory_path)).to be(false)
	end

	it 'uses the provided temporary directory prefix' do
		directory_basename = nil

		described_class.with_dir(prefix: 'custom-prefix-') do |directory|
			directory_basename = File.basename(directory)
		end

		expect(directory_basename).to start_with('custom-prefix-')
	end

	it 'still removes successful directories when keep_on_error is true' do
		temporary_directory_path = nil

		described_class.with_dir(keep_on_error: true) do |directory|
			temporary_directory_path = directory
		end

		expect(Dir.exist?(temporary_directory_path)).to be(false)
	end

	it 'keeps the temporary directory on failure when keep_on_error is true' do
		temporary_directory_path = nil

		expect do
			described_class.with_dir(keep_on_error: true) do |directory|
				temporary_directory_path = directory
				raise 'intentional failure'
			end
		end.to raise_error(RuntimeError, 'intentional failure')

		expect(Dir.exist?(temporary_directory_path)).to be(true)
		FileUtils.remove_entry(temporary_directory_path)
	end

	it 'removes the temporary directory on failure when keep_on_error is false' do
		temporary_directory_path = nil

		expect do
			described_class.with_dir do |directory|
				temporary_directory_path = directory
				raise 'intentional failure'
			end
		end.to raise_error(RuntimeError, 'intentional failure')

		expect(Dir.exist?(temporary_directory_path)).to be(false)
	end
end
