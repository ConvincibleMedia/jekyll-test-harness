# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::FixtureLoader do
	# Returns the project root used for fixture path resolution in these tests.
	def project_root
		File.expand_path('../..', __dir__)
	end

	describe '.resolve_path' do
		it 'resolves fixture paths within the configured project root' do
			resolved_path = described_class.resolve_path(file: 'spec/fixtures/loader/sample.txt', project_root: project_root)
			expect(resolved_path).to eq(File.expand_path('spec/fixtures/loader/sample.txt', project_root))
		end

		it 'rejects fixture paths that escape the configured project root' do
			expect do
				described_class.resolve_path(file: '../Gemfile', project_root: project_root)
			end.to raise_error(ArgumentError, /escapes the configured project root/)
		end
	end

	describe '.read_text' do
		it 'reads fixture text content from project-relative paths' do
			text = described_class.read_text(file: 'spec/fixtures/loader/sample.txt', project_root: project_root)
			expect(text).to eq("Loader fixture sample text.\n")
		end

		it 'raises a clear error when the fixture file does not exist' do
			expect do
				described_class.read_text(file: 'spec/fixtures/loader/missing.txt', project_root: project_root)
			end.to raise_error(ArgumentError, /Fixture file was not found/)
		end

		it 'raises a clear error when file is not a path-like value' do
			expect do
				described_class.read_text(file: Object.new, project_root: project_root)
			end.to raise_error(ArgumentError, /file must be a String path or Pathname/)
		end
	end

	describe '.read_yaml_hash' do
		it 'reads and returns YAML hashes from fixture files' do
			hash = described_class.read_yaml_hash(file: 'spec/fixtures/complex/config/base.yml', project_root: project_root)
			expect(hash.dig('collections', 'guides', 'output')).to be(true)
		end

		it 'returns an empty hash when YAML fixture content is nil' do
			hash = described_class.read_yaml_hash(file: 'spec/fixtures/loader/empty.yml', project_root: project_root)
			expect(hash).to eq({})
		end

		it 'raises a clear error when fixture YAML root is not a hash' do
			expect do
				described_class.read_yaml_hash(file: 'spec/fixtures/loader/list.yml', project_root: project_root)
			end.to raise_error(ArgumentError, /must contain a YAML hash/)
		end
	end
end
