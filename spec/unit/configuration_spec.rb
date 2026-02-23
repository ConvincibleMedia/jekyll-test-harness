# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::Configuration do
	around do |example|
		described_class.reset_runtime!
		example.run
		described_class.reset_runtime!
	end

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

	describe '.configure_runtime!' do
		it 'sets failure mode and resolves a relative output directory from project root' do
			described_class.configure_runtime!(failures: :keep, output: 'tmp/jth-sites', project_root: '/workspace')

			expect(described_class.failure_mode).to eq(:keep)
			expect(described_class.keep_failures?).to be(true)
			expect(described_class.project_root).to eq(File.expand_path('/workspace'))
			expect(described_class.output).to eq(File.expand_path('/workspace/tmp/jth-sites'))
		end

		it 'accepts clean mode and nil output directory' do
			described_class.configure_runtime!(failures: :clean, output: nil, project_root: '/workspace')

			expect(described_class.failure_mode).to eq(:clean)
			expect(described_class.keep_failures?).to be(false)
			expect(described_class.output).to be_nil
		end

		it 'keeps absolute output paths unchanged' do
			absolute_output = File.expand_path('/tmp/jth-absolute')
			described_class.configure_runtime!(failures: :clean, output: absolute_output, project_root: '/workspace')
			expect(described_class.output).to eq(absolute_output)
		end

		it 'raises a clear error for unsupported failures modes' do
			expect do
				described_class.configure_runtime!(failures: :unknown, output: nil, project_root: '/workspace')
			end.to raise_error(ArgumentError, /Unsupported value for failures/)
		end

		it 'raises a clear error for invalid failures value types' do
			expect do
				described_class.configure_runtime!(failures: Object.new, output: nil, project_root: '/workspace')
			end.to raise_error(ArgumentError, /failures must be a Symbol or non-empty String/)
		end

		it 'raises a clear error for empty output strings' do
			expect do
				described_class.configure_runtime!(failures: :clean, output: '   ', project_root: '/workspace')
			end.to raise_error(ArgumentError, /must not be empty/)
		end

		it 'raises a clear error for invalid output value types' do
			expect do
				described_class.configure_runtime!(failures: :clean, output: Object.new, project_root: '/workspace')
			end.to raise_error(ArgumentError, /output must be a String path or Pathname/)
		end
	end

	describe '.temporary_directory_prefix' do
		it 'returns the shared prefix used for temporary site directories' do
			expect(described_class.temporary_directory_prefix).to eq('jekyll-test-harness')
		end
	end
end

