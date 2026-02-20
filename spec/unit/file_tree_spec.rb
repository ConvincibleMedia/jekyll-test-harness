# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::FileTree do
	it 'writes nested file trees into the target root directory' do
		Jekyll::TestHarness::TemporaryDirectory.with_dir do |temporary_directory|
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

	it 'writes YAML data and creates parent directories' do
		Jekyll::TestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			yaml_path = File.join(temporary_directory, 'site', '_config.yml')
			described_class.write_yaml(yaml_path, 'quiet' => true, 'incremental' => false)

			written_yaml = File.read(yaml_path)
			expect(written_yaml).to include('quiet: true')
			expect(written_yaml).to include('incremental: false')
		end
	end
end
