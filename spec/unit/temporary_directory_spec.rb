# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::TemporaryDirectory do
	it 'raises a harness-specific error when no block is supplied' do
		expect do
			described_class.with_dir
		end.to raise_error(JekyllTestHarness::MissingBlockError)
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

	it 'uses label segments and adds a numeric suffix for uniqueness' do
		created_directories = []

		2.times do
			described_class.with_dir(label: 'features/tags/special_tag') do |directory|
				created_directories << directory
				expect(directory.tr('\\', '/')).to include('/features/tags/')
				expect(File.basename(directory)).to match(/special-tag-\d+\z/)
			end
		end

		expect(created_directories.map { |directory| File.basename(directory) }.uniq.length).to eq(2)
	end

	it 'uses the provided prefix when no label is supplied' do
		basename = nil

		described_class.with_dir(prefix: 'custom-prefix') do |directory|
			basename = File.basename(directory)
		end

		expect(basename).to match(/custom-prefix-\d+\z/)
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

	it 'leaves the configured root in place after cleanup' do
		Dir.mktmpdir('jth-root-prune-') do |workspace_root|
			configured_root = File.join(workspace_root, 'tmp', 'sites')

			described_class.with_dir(root_directory: configured_root, label: 'spec/example') do |directory|
				expect(directory).to start_with(File.expand_path(configured_root))
			end

			expect(Dir.exist?(configured_root)).to be(true)
		end
	end
end
