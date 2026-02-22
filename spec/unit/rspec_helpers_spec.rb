# frozen_string_literal: true

require_relative '../spec_helper'
require 'yaml'

RSpec.describe JekyllTestHarness::Helpers do
	# Provides a simple host object for exercising helper module methods directly.
	let(:helper_host_class) do
		Class.new do
			include JekyllTestHarness::Helpers
		end
	end

	# Returns a minimal valid file tree for successful Jekyll builds.
	def minimal_site_files(body = 'Helper output')
		{
			'_layouts' => {
				'default.html' => '<html><body>{{ content }}</body></html>'
			},
			'index.md' => "---\nlayout: default\n---\n#{body}\n"
		}
	end

	around do |example|
		JekyllTestHarness::Configuration.reset_runtime!
		example.run
		JekyllTestHarness::Configuration.reset_runtime!
	end

	it 'delegates jekyll_merge to SiteHarness.jekyll_merge' do
		host = helper_host_class.new
		merged = host.jekyll_merge({ 'a' => { 'b' => 1 } }, { 'a' => { 'c' => 2 } })
		expect(merged).to eq('a' => { 'b' => 1, 'c' => 2 })
	end

	it 'raises a harness error when jekyll_build is called without a block' do
		host = helper_host_class.new

		expect do
			host.jekyll_build
		end.to raise_error(JekyllTestHarness::MissingBlockError)
	end

	it 'creates JekyllBlueprint values from config and files' do
		host = helper_host_class.new
		blueprint = host.jekyll_blueprint(config: { 'a' => 1 }, files: { 'index.md' => 'body' })

		expect(blueprint).to be_a(JekyllTestHarness::JekyllBlueprint)
		expect(blueprint.config).to eq('a' => 1)
		expect(blueprint.files).to eq('index.md' => 'body')
	end

	it 'uses buffered jekyll_files and jekyll_config values when jekyll_build omits them' do
		host = helper_host_class.new
		host.jekyll_config('my_plugin' => { 'mode' => 'buffered' })
		returned_files = host.jekyll_files do
			folder '_layouts' do
				file 'default.html' do
					'<html><body>{{ content }}</body></html>'
				end
			end
			file 'index.md' do
				frontmatter('layout' => 'default')
				contents('Buffered file body.')
			end
		end

		expect(returned_files).to include('_layouts', 'index.md')

		host.jekyll_build do |_site, files|
			written_config = YAML.safe_load(files.source_read('_config.yml'))
			expect(written_config.dig('my_plugin', 'mode')).to eq('buffered')
			expect(files.read('index.html')).to include('Buffered file body.')
		end
	end

	it 'supports direct file return values as string, array, and hash' do
		host = helper_host_class.new
		host.jekyll_files do
			folder '_layouts' do
				file 'default.html' do
					'<html><body>{{ content }}</body></html>'
				end
			end
			file 'index.md' do
				[
					'---',
					'layout: default',
					'---',
					'Array body.'
				]
			end
			file 'data.yml' do
				{ 'mode' => 'hash-return' }
			end
		end

		host.jekyll_build do |_site, files|
			expect(files.read('index.html')).to include('Array body.')
			expect(files.source_read('data.yml')).to include('mode: hash-return')
		end
	end

	it 'flushes config and files buffers every time jekyll_build is called' do
		host = helper_host_class.new
		host.jekyll_files do
			file 'buffered.txt' do
				'buffered'
			end
		end

		host.jekyll_build(files: minimal_site_files('First build')) do |_site, files|
			expect(files.read('index.html')).to include('First build')
			expect(files.source_list).not_to include('buffered.txt')
		end

		host.jekyll_build do |_site, files|
			expect(files.source_list).to eq(['_config.yml'])
		end
	end

	it 'accepts a blueprint in jekyll_build and merges explicit config/files over it' do
		host = helper_host_class.new
		blueprint = host.jekyll_blueprint(
			config: { 'my_plugin' => { 'mode' => 'base', 'shared' => true } },
			files: minimal_site_files('Blueprint body')
		)
		override_files = {
			'index.md' => "---\nlayout: default\n---\nOverride body\n"
		}

		host.jekyll_build(blueprint, config: { 'my_plugin' => { 'mode' => 'override' } }, files: override_files) do |_site, files|
			written_config = YAML.safe_load(files.source_read('_config.yml'))
			expect(written_config['my_plugin']).to eq('mode' => 'override', 'shared' => true)
			expect(files.read('index.html')).to include('Override body')
		end
	end

	it 'supports loading config and file content from fixtures relative to project root' do
		host = helper_host_class.new
		host.jekyll_config(file: 'spec/fixtures/dsl/config.yml')
		host.jekyll_files do
			folder '_layouts' do
				file 'default.html' do
					contents(file: 'spec/fixtures/dsl/layout.html')
				end
			end
			file 'index.md' do
				frontmatter(file: 'spec/fixtures/dsl/frontmatter.yml')
				contents(file: 'spec/fixtures/dsl/body.md')
			end
		end

		host.jekyll_build do |_site, files|
			written_config = YAML.safe_load(files.source_read('_config.yml'))
			expect(written_config.dig('my_plugin', 'mode')).to eq('fixture')
			expect(files.read('index.html')).to include('Fixture body content')
		end
	end

	it 'warns and ignores source/destination when provided through jekyll_config and jekyll_build' do
		host = helper_host_class.new
		host.jekyll_config('source' => '/buffer/source', 'destination' => '/buffer/destination')

		expect(JekyllTestHarness::SiteHarness).to receive(:warn).with(/ignoring config\['source'\]/)
		expect(JekyllTestHarness::SiteHarness).to receive(:warn).with(/ignoring config\['destination'\]/)

		host.jekyll_build(
			config: { 'source' => '/inline/source', 'destination' => '/inline/destination' },
			files: minimal_site_files('Safety test')
		) do |_site, files|
			written_config = YAML.safe_load(files.source_read('_config.yml'))
			expect(written_config['source']).to eq(files.source_dir)
			expect(written_config['destination']).to eq(files.dir)
		end
	end
end

RSpec.describe JekyllTestHarness do
	around do |example|
		JekyllTestHarness::Configuration.reset_runtime!
		example.run
		JekyllTestHarness::Configuration.reset_runtime!
	end

	it 'installs helpers into the global RSpec configuration' do
		configuration = described_class.install!(framework: :rspec)
		expect(configuration).to equal(::RSpec.configuration)
		expect(::RSpec.configuration.singleton_class.included_modules).to include(JekyllTestHarness::Helpers)
	end

	it 'supports configure as an alias for install!' do
		returned_configuration = described_class.configure(framework: :rspec)

		expect(returned_configuration).to equal(::RSpec.configuration)
		expect(::RSpec.configuration.singleton_class.included_modules).to include(JekyllTestHarness::Helpers)
	end

	it 'allows framework to be omitted and auto-detected' do
		configuration = described_class.install!
		expect(configuration).to equal(::RSpec.configuration)
	end

	it 'applies failures and output install settings' do
		original_directory = Dir.pwd

		begin
			Dir.mktmpdir('jth-install-root-') do |project_root|
				Dir.chdir(project_root)
				described_class.install!(framework: :rspec, failures: :keep, output: 'tmp/sites')
				expect(JekyllTestHarness::Configuration.failure_mode).to eq(:keep)
				expect(JekyllTestHarness::Configuration.output).to eq(File.expand_path('tmp/sites', project_root))
			end
		ensure
			Dir.chdir(original_directory)
		end
	end

	it 'raises a clear error when explicit RSpec installation is requested but RSpec is unavailable' do
		allow(described_class).to receive(:rspec_available?).and_return(false)

		expect do
			described_class.install!(framework: :rspec)
		end.to raise_error(NameError, /RSpec is not available/)
	end

	it 'auto-detects RSpec when it is the only loaded framework' do
		allow(described_class).to receive(:available_frameworks).and_return([:rspec])
		returned_configuration = described_class.install!(framework: :auto)

		expect(returned_configuration).to equal(::RSpec.configuration)
	end

	it 'raises clear guidance when auto detection finds no framework' do
		allow(described_class).to receive(:available_frameworks).and_return([])

		expect do
			described_class.install!
		end.to raise_error(NameError, /No supported test framework is loaded/)
	end

	it 'raises clear guidance when auto detection finds multiple frameworks' do
		allow(described_class).to receive(:available_frameworks).and_return(%i[rspec minitest])

		expect do
			described_class.install!
		end.to raise_error(ArgumentError, /Multiple supported frameworks are loaded/)
	end

	it 'raises a clear error for unsupported framework values' do
		expect do
			described_class.install!(framework: :unknown)
		end.to raise_error(ArgumentError, /Unsupported framework/)
	end

	it 'raises a clear error for unsupported failures values' do
		expect do
			described_class.install!(framework: :rspec, failures: :unknown)
		end.to raise_error(ArgumentError, /Unsupported failures mode/)
	end
end
