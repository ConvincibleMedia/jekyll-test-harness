# frozen_string_literal: true

require_relative '../spec_helper'
require 'yaml'

RSpec.describe JekyllTestHarness::FileTree do
	it 'writes nested file trees into the target root directory' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			root = File.join(temporary_directory, 'site')
			files = {
				'_layouts' => {
					'default.html' => '<html>{{ content }}</html>'
				},
				'_posts' => {
					'2026-01-01-post.md' => "---\nlayout: default\n---\nPost\n"
				}
			}

			described_class.write(root, files)

			expect(File.read(File.join(root, '_layouts', 'default.html'))).to include('{{ content }}')
			expect(File.read(File.join(root, '_posts', '2026-01-01-post.md'))).to include('layout: default')
		end
	end

	it 'supports symbol keys and stringifies non-string contents' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			root = File.join(temporary_directory, 'site')
			described_class.write(
				root,
				docs: {
					count: 12,
					nullable: nil
				}
			)

			expect(File.read(File.join(root, 'docs', 'count'))).to eq('12')
			expect(File.read(File.join(root, 'docs', 'nullable'))).to eq('')
		end
	end

	it 'writes YAML data and creates parent directories' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			yaml_path = File.join(temporary_directory, 'site', '_config.yml')
			described_class.write_yaml(yaml_path, 'quiet' => true, 'incremental' => false)

			written_yaml = File.read(yaml_path)
			expect(written_yaml).to include('quiet: true')
			expect(written_yaml).to include('incremental: false')
		end
	end

	it 'writes parseable YAML content' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			yaml_path = File.join(temporary_directory, 'site', '_config.yml')
			data = { 'quiet' => true, 'nested' => { 'mode' => 'test' } }
			described_class.write_yaml(yaml_path, data)

			parsed = YAML.safe_load(File.read(yaml_path))
			expect(parsed).to eq(data)
		end
	end
end

