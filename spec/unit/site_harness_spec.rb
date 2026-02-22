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

		it 'returns a deep clone so mutating merged output does not mutate inputs' do
			base = { 'nested' => { 'list' => ['a'] } }
			overrides = { 'nested' => { 'value' => 'b' } }
			merged = described_class.merge_data(base, overrides)
			merged['nested']['list'] << 'mutated'
			merged['nested']['value'].replace('changed')

			expect(base).to eq('nested' => { 'list' => ['a'] })
			expect(overrides).to eq('nested' => { 'value' => 'b' })
		end

		it 'returns a deep clone of overrides when base is not a hash' do
			overrides = { 'nested' => { 'value' => 'x' } }
			merged = described_class.merge_data(['not-hash'], overrides)
			merged['nested']['value'].replace('changed')

			expect(overrides).to eq('nested' => { 'value' => 'x' })
		end

		it 'returns a deep clone of base when overrides are nil' do
			base = { 'array' => [1, 2] }
			merged = described_class.merge_data(base, nil)
			merged['array'] << 3

			expect(base).to eq('array' => [1, 2])
		end
	end

	describe '.with_site' do
		it 'raises a harness-specific error when no block is supplied' do
			expect do
				described_class.with_site
			end.to raise_error(JekyllTestHarness::MissingBlockError)
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

		it 'merges base and per-example config with per-example values taking precedence' do
			base_config = {
				'quiet' => false,
				'incremental' => true,
				'my_plugin' => { 'mode' => 'base', 'shared' => true }
			}
			config = {
				'quiet' => true,
				'my_plugin' => { 'mode' => 'override' }
			}

			described_class.with_site(base_config: base_config, config: config) do |_site, paths|
				written_config = YAML.safe_load(paths.read_source('_config.yml'))
				expect(written_config['quiet']).to be(true)
				expect(written_config['incremental']).to be(true)
				expect(written_config['my_plugin']).to eq('mode' => 'override', 'shared' => true)
			end
		end

		it 'merges base and per-example files with per-example values taking precedence' do
			base_files = {
				'_layouts' => {
					'base.html' => '<html><body>{{ content }}</body></html>',
					'shared.html' => '<p>base</p>'
				},
				'notes' => {
					'base.txt' => 'base'
				}
			}
			files = {
				'_layouts' => {
					'shared.html' => '<p>override</p>'
				},
				'notes' => {
					'override.txt' => 'override'
				}
			}

			described_class.with_site(base_files: base_files, files: files) do |_site, paths|
				expect(paths.read_source('_layouts/base.html')).to include('{{ content }}')
				expect(paths.read_source('_layouts/shared.html')).to include('override')
				expect(paths.read_source('notes/base.txt')).to eq('base')
				expect(paths.read_source('notes/override.txt')).to eq('override')
			end
		end

		it 'does not mutate caller-provided config and file hashes' do
			base_config = { 'my_plugin' => { 'flag' => true } }
			config = { 'my_plugin' => { 'nested' => 'value' } }
			base_files = { 'docs' => { 'base.txt' => 'base' } }
			files = { 'docs' => { 'override.txt' => 'override' } }
			base_config_snapshot = Marshal.load(Marshal.dump(base_config))
			config_snapshot = Marshal.load(Marshal.dump(config))
			base_files_snapshot = Marshal.load(Marshal.dump(base_files))
			files_snapshot = Marshal.load(Marshal.dump(files))

			described_class.with_site(base_config: base_config, config: config, base_files: base_files, files: files) do |_site, _paths|
			end

			expect(base_config).to eq(base_config_snapshot)
			expect(config).to eq(config_snapshot)
			expect(base_files).to eq(base_files_snapshot)
			expect(files).to eq(files_snapshot)
		end

		it 'yields a built Jekyll::Site and a Paths helper' do
			described_class.with_site do |site, paths|
				expect(site).to be_a(Jekyll::Site)
				expect(paths).to be_a(JekyllTestHarness::Paths)
			end
		end

		it 'builds the default scaffold into output html' do
			described_class.with_site do |_site, paths|
				expect(paths.read_output('index.html')).to include('Hello from the Jekyll test harness default scaffold.')
			end
		end

		it 'supports custom builds when default scaffold is disabled' do
			files = {
				'_layouts' => {
					'custom.html' => '<html><body>{{ content }}</body></html>'
				},
				'index.md' => <<~MARKDOWN
					---
					layout: custom
					---
					Custom scaffold disabled build.
				MARKDOWN
			}

			described_class.with_site(default_scaffold: false, files: files) do |_site, paths|
				expect(paths.read_output('index.html')).to include('Custom scaffold disabled build.')
			end
		end

		it 'removes temporary directories after successful execution' do
			temporary_root = nil

			described_class.with_site do |_site, paths|
				temporary_root = File.dirname(paths.source)
				expect(Dir.exist?(temporary_root)).to be(true)
			end

			expect(Dir.exist?(temporary_root)).to be(false)
		end

		it 'removes temporary directories after failure when keep_site_on_failure is false' do
			temporary_root = nil

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(files: { '_layouts' => { 'default.html' => '{% if %}' } }) { |_site, _paths| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				temporary_root = File.dirname(error.source_path)
			}

			expect(Dir.exist?(temporary_root)).to be(false)
		end

		it 'keeps temporary directories after failure when keep_site_on_failure is true' do
			temporary_root = nil

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(keep_site_on_failure: true, files: { '_layouts' => { 'default.html' => '{% if %}' } }) { |_site, _paths| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				temporary_root = File.dirname(error.source_path)
			}

			expect(Dir.exist?(temporary_root)).to be(true)
			FileUtils.remove_entry(temporary_root)
		end

		it 'wraps build errors with source, destination, and config context' do
			config = { 'my_plugin' => { 'mode' => 'diagnostic' } }
			files = { '_layouts' => { 'default.html' => '{% if %}' } }

			expect do
				suppress_expected_build_stderr do
					described_class.with_site(config: config, files: files) { |_site, _paths| }
				end
			end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
				expect(error.source_path).to be_a(String)
				expect(error.destination_path).to be_a(String)
				expect(error.config_snapshot.dig('my_plugin', 'mode')).to eq('diagnostic')
				expect(error.original_error).to be_a(StandardError)
			}
		end
	end
end

