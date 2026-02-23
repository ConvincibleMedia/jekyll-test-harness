# frozen_string_literal: true

require_relative '../spec_helper'
require 'yaml'

RSpec.describe JekyllTestHarness::FilesDsl do
	# Provides delegated helper methods used by FilesDsl method-missing checks.
	let(:host_context) do
		Class.new do
			def delegated_prefix
				'delegated'
			end

			def delegated_suffix(value)
				"#{value}-from-host"
			end
		end.new
	end

	# Returns the project root used to resolve fixture file paths.
	let(:project_root) { File.expand_path('../..', __dir__) }

	it 'returns an empty hash when no DSL block is provided' do
		tree = described_class.new(host_context: host_context, project_root: project_root).build
		expect(tree).to eq({})
	end

	it 'builds nested folders and files with helper delegation and fixture-backed fragments' do
		tree = described_class.new(host_context: host_context, project_root: project_root).build do
			folder '_drafts'
			file 'empty.txt'
			folder 'docs' do
				file 'delegated.txt' do
					delegated_suffix(delegated_prefix)
				end
				file 'index.md' do
					frontmatter(file: 'spec/fixtures/complex/frontmatter/guide.yml', 'title' => 'DSL title', tags: %w[alpha beta])
					contents(file: 'spec/fixtures/complex/body/guide.md')
					contents("\nInline appendix.\n")
					'ignored return value'
				end
			end
		end

		expect(tree['_drafts']).to eq({})
		expect(tree['empty.txt']).to eq('')
		expect(tree.dig('docs', 'delegated.txt')).to eq('delegated-from-host')

		index_payload = tree.dig('docs', 'index.md')
		expect(index_payload).to include('Fixture complex body line one.')
		expect(index_payload).to include('Inline appendix.')
		expect(index_payload).not_to include('ignored return value')

		frontmatter_match = index_payload.match(/\A---\n(.*?)---\n\n/m)
		expect(frontmatter_match).not_to be_nil
		safe_load_parameters = YAML.method(:safe_load).parameters
		frontmatter_hash = if safe_load_parameters.any? { |parameter_type, parameter_name| parameter_type == :key && parameter_name == :permitted_classes }
			YAML.safe_load(frontmatter_match[1], permitted_classes: [Symbol], permitted_symbols: [:tags], aliases: false)
		else
			YAML.safe_load(frontmatter_match[1], [Symbol], [:tags], false)
		end
		expect(frontmatter_hash['layout']).to eq('default')
		expect(frontmatter_hash['title']).to eq('DSL title')
		expect(frontmatter_hash[:tags]).to eq(%w[alpha beta])
	end

	it 'raises a clear error when frontmatter hash input is invalid' do
		expect do
			described_class.new(host_context: host_context, project_root: project_root).build do
				file 'broken.md' do
					frontmatter('invalid')
				end
			end
		end.to raise_error(ArgumentError, /frontmatter hash must be a Hash/)
	end

	it 'raises a clear error when a file block returns an unsupported value type' do
		expect do
			described_class.new(host_context: host_context, project_root: project_root).build do
				file 'broken.md' do
					Object.new
				end
			end
		end.to raise_error(ArgumentError, /File DSL block must return/)
	end

	it 'raises a clear error when a folder or file name is blank' do
		expect do
			described_class.new(host_context: host_context, project_root: project_root).build do
				folder '   '
			end
		end.to raise_error(ArgumentError, /folder name must not be empty/)
	end

	it 'raises when a fixture path escapes the configured project root' do
		expect do
			described_class.new(host_context: host_context, project_root: project_root).build do
				file 'broken.md' do
					contents(file: '../Gemfile')
				end
			end
		end.to raise_error(ArgumentError, /escapes the configured project root/)
	end

	it 'raises NameError when unknown helper methods are called without host support' do
		expect do
			described_class.new(host_context: nil, project_root: project_root).build do
				unknown_helper_method
			end
		end.to raise_error(NameError)
	end
end
