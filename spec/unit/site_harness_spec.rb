# frozen_string_literal: true

require_relative '../spec_helper'
require 'stringio'
require 'yaml'

RSpec.describe JekyllTestHarness::SiteHarness do
	# Silences expected Liquid parse noise from intentionally-invalid fixtures in this spec file.
	def suppress_expected_build_stderr
		original_stderr = $stderr
		$stderr = StringIO.new
		yield
	ensure
		$stderr = original_stderr
	end

	# Returns a minimal valid Jekyll site file tree used by multiple examples.
	def minimal_site_files(body = 'Hello from the harness')
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

	describe '.jekyll_merge' do
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

			merged = described_class.jekyll_merge(base, overrides)

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

		it 'returns a deep clone so mutating merged output does not mutate inputs' do
			base = { 'nested' => { 'list' => ['a'] } }
			overrides = { 'nested' => { 'value' => 'b' } }
			merged = described_class.jekyll_merge(base, overrides)
			merged['nested']['list'] << 'mutated'
			merged['nested']['value'].replace('changed')

			expect(base).to eq('nested' => { 'list' => ['a'] })
			expect(overrides).to eq('nested' => { 'value' => 'b' })
		end

		it 'merges JekyllBlueprint values and returns a new JekyllBlueprint' do
			base = JekyllTestHarness::JekyllBlueprint.new(config: { 'a' => { 'b' => 1 } }, files: { 'a.txt' => 'base' })
			overrides = JekyllTestHarness::JekyllBlueprint.new(config: { 'a' => { 'c' => 2 } }, files: { 'b.txt' => 'override' })

			merged = described_class.jekyll_merge(base, overrides)

			expect(merged).to be_a(JekyllTestHarness::JekyllBlueprint)
			expect(merged).not_to equal(base)
			expect(merged.config).to eq('a' => { 'b' => 1, 'c' => 2 })
			expect(merged.files).to eq('a.txt' => 'base', 'b.txt' => 'override')
		end

		it 'raises for unsupported merge types' do
			expect do
				described_class.jekyll_merge('not-a-hash', {})
			end.to raise_error(ArgumentError, /does not support base value type/)
		end
	end

	describe '.with_site' do
		it 'raises a harness-specific error when no block is supplied' do
			expect do
				described_class.with_site
			end.to raise_error(JekyllTestHarness::MissingBlockError)
		end

		it 'does not write a default scaffold when no files are supplied' do
			described_class.with_site do |_site, files|
				expect(files.source_list).to eq(['_config.yml'])
			end
		end

		it 'yields a built Jekyll::Site and a Files helper' do
			described_class.with_site(files: minimal_site_files) do |site, files|
				expect(site).to be_a(Jekyll::Site)
				expect(files).to be_a(JekyllTestHarness::Files)
				expect(files.read('index.html')).to include('Hello from the harness')
			end
		end

		it 'applies provided config values on top of default config values' do
			config = {
				'quiet' => false,
				'incremental' => true,
				'my_plugin' => { 'mode' => 'diagnostic' }
			}

			described_class.with_site(config: config, files: minimal_site_files) do |_site, files|
				written_config = YAML.safe_load(files.source_read('_config.yml'))
				expect(written_config['quiet']).to be(false)
				expect(written_config['incremental']).to be(true)
				expect(written_config.dig('my_plugin', 'mode')).to eq('diagnostic')
			end
		end

		it 'ignores user-provided source and destination and warns for both keys' do
			config = {
				'source' => '/user/source',
				'destination' => '/user/destination',
				'my_plugin' => { 'mode' => 'sanitised' }
			}

			expect(described_class).to receive(:warn).with(/ignoring config\['source'\]/)
			expect(described_class).to receive(:warn).with(/ignoring config\['destination'\]/)

			described_class.with_site(config: config, files: minimal_site_files('Sanitised source/destination')) do |_site, files|
				written_config = YAML.safe_load(files.source_read('_config.yml'))
				expect(written_config['source']).to eq(files.source_dir)
				expect(written_config['destination']).to eq(files.dir)
				expect(written_config.dig('my_plugin', 'mode')).to eq('sanitised')
			end
		end

		it 'does not mutate caller-provided config and file hashes' do
			config = { 'my_plugin' => { 'nested' => 'value' } }
			files = minimal_site_files('Mutability check')
			config_snapshot = Marshal.load(Marshal.dump(config))
			files_snapshot = Marshal.load(Marshal.dump(files))

			described_class.with_site(config: config, files: files) do |_site, _files|
			end

			expect(config).to eq(config_snapshot)
			expect(files).to eq(files_snapshot)
		end

		it 'removes temporary directories after successful execution' do
			temporary_root = nil

			described_class.with_site(files: minimal_site_files) do |_site, files|
				temporary_root = File.dirname(files.source_dir)
				expect(Dir.exist?(temporary_root)).to be(true)
			end

			expect(Dir.exist?(temporary_root)).to be(false)
		end

		it 'removes temporary directories after failure when failures mode is clean' do
			temporary_root = nil
			invalid_files = {
				'_layouts' => { 'default.html' => '{% if %}' },
				'index.md' => "---\nlayout: default\n---\nBroken\n"
			}

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(files: invalid_files) { |_site, _files| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				temporary_root = File.dirname(error.source_path)
			}

			expect(Dir.exist?(temporary_root)).to be(false)
		end

		it 'keeps temporary directories after failure when failures mode is keep' do
			temporary_root = nil
			invalid_files = {
				'_layouts' => { 'default.html' => '{% if %}' },
				'index.md' => "---\nlayout: default\n---\nBroken\n"
			}
			JekyllTestHarness::Configuration.configure_runtime!(failures: :keep, output: nil, project_root: Dir.pwd)

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(files: invalid_files) { |_site, _files| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				temporary_root = File.dirname(error.source_path)
			}

			expect(Dir.exist?(temporary_root)).to be(true)
			FileUtils.remove_entry(temporary_root)
		end

		it 'wraps build errors with source, destination, and config context' do
			config = { 'my_plugin' => { 'mode' => 'diagnostic' } }
			files = {
				'_layouts' => { 'default.html' => '{% if %}' },
				'index.md' => "---\nlayout: default\n---\nBroken\n"
			}

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(config: config, files: files) { |_site, _files| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				expect(error.source_path).to be_a(String)
				expect(error.destination_path).to be_a(String)
				expect(error.config_snapshot.dig('my_plugin', 'mode')).to eq('diagnostic')
				expect(error.original_error).to be_a(StandardError)
			}
		end

		it 'uses configured output root for generated temporary site directories' do
			Dir.mktmpdir('jth-project-root-') do |project_root|
				configured_root = File.join(project_root, 'tmp', 'sites')
				JekyllTestHarness::Configuration.configure_runtime!(failures: :clean, output: 'tmp/sites', project_root: project_root)

				described_class.with_site(files: minimal_site_files('Configured root')) do |_site, files|
					expect(files.source_dir).to start_with(File.expand_path(configured_root))
				end

				expect(Dir.exist?(configured_root)).to be(true)
			end
		end

		it 'builds directory names that include a counter suffix for uniqueness' do
			temporary_roots = []

			2.times do
				described_class.with_site(files: minimal_site_files('Counter')) do |_site, files|
					temporary_roots << File.dirname(files.source_dir)
				end
			end

			expect(temporary_roots.uniq.length).to eq(2)
			expect(temporary_roots.map { |path| File.basename(path) }).to all(match(/-\d+\z/))
			expect(temporary_roots.first.tr('\\', '/')).to include('site-harness-spec')
		end
	end
end
