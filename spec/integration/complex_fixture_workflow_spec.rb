# frozen_string_literal: true

require_relative '../spec_helper'
require 'yaml'

RSpec.describe 'Complex fixture workflow' do
	it 'supports layered blueprints with fixture-driven DSL content and deep config merges' do
		base_blueprint = jekyll_blueprint(
			config: {
				'my_plugin' => {
					'mode' => 'blueprint-base',
					'flags' => { 'blueprint' => true }
				}
			},
			files: {
				'_guides' => {
					'blueprint.md' => "---\nlayout: default\ntitle: Blueprint guide\n---\nBlueprint body.\n"
				}
			}
		)
		overlay_blueprint = jekyll_blueprint(
			config: {
				'my_plugin' => {
					'flags' => { 'overlay' => true }
				}
			},
			files: {
				'_guides' => {
					'overlay.md' => "---\nlayout: default\ntitle: Overlay guide\n---\nOverlay body.\n"
				}
			}
		)
		composed_blueprint = jekyll_merge(base_blueprint, overlay_blueprint)

		jekyll_config(file: 'spec/fixtures/complex/config/base.yml')
		jekyll_config({ 'my_plugin' => { 'flags' => { 'inline' => true } } }, file: 'spec/fixtures/complex/config/feature_flags.yml')

		jekyll_files do
			folder '_layouts' do
				file 'default.html' do
					contents(file: 'spec/fixtures/complex/layouts/default.html')
				end
			end

			folder '_includes' do
				file 'banner.html' do
					contents(file: 'spec/fixtures/complex/includes/banner.html')
					contents(' -- inline suffix')
				end
			end

			folder '_guides' do
				file 'dsl-guide.md' do
					frontmatter(file: 'spec/fixtures/complex/frontmatter/guide.yml', 'title' => 'DSL guide', 'permalink' => '/guides/dsl-guide.html')
					contents(file: 'spec/fixtures/complex/body/guide.md')
					contents("\nInline guide addition.\n")
				end
			end
		end

		jekyll_build(composed_blueprint) do |site, files|
			guide_documents = site.collections.fetch('guides').docs
			expect(guide_documents.map(&:basename_without_ext)).to include('blueprint', 'overlay', 'dsl-guide')

			dsl_html = files.read('guides/dsl-guide.html')
			expect(dsl_html).to include('Fixture banner text')
			expect(dsl_html).to include('fixture-tag-output')
			expect(dsl_html).to include('Fixture complex body line one.')
			expect(dsl_html).to include('Inline guide addition.')

			expect(files.read('guides/blueprint.html')).to include('Blueprint body.')
			expect(files.read('guides/overlay.html')).to include('Overlay body.')

			written_config = YAML.safe_load(files.source_read('_config.yml'))
			expect(written_config.dig('collections', 'guides', 'output')).to be(true)
			expect(written_config.dig('collections', 'guides', 'permalink')).to eq('/guides/:name.html')
			expect(written_config.dig('my_plugin', 'mode')).to eq('fixture-feature')
			expect(written_config.dig('my_plugin', 'flags')).to include(
				'blueprint' => true,
				'overlay' => true,
				'base' => true,
				'feature' => true,
				'inline' => true
			)

			expect(files.source_list('_guides')).to include('_guides/blueprint.md', '_guides/dsl-guide.md', '_guides/overlay.md')
			expect(files.list('guides')).to include('guides/blueprint.html', 'guides/dsl-guide.html', 'guides/overlay.html')
		end
	end
end
