# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Fixture plugin integration' do
	it 'executes fixture hooks and renders fixture Liquid tags in generated output' do
		files = {
			'_layouts' => {
				'default.html' => <<~HTML
					<!doctype html>
					<html>
						<body>
							{% fixture_greeting %}
							{{ content }}
						</body>
					</html>
				HTML
			},
			'_posts' => {
				'2026-01-01-fixture-post.md' => <<~MARKDOWN
					---
					layout: default
					permalink: /docs/fixture-post.html
					---
					Fixture post body.
				MARKDOWN
			}
		}

		build_jekyll_site(files: files) do |site, paths|
			document = site.collections.fetch('posts').docs.find { |doc| doc.basename_without_ext.end_with?('fixture-post') }
			expect(document.data['fixture_hook_marker']).to eq('hooked-by-fixture')

			html = paths.read_output('docs/fixture-post.html')
			expect(html).to include('fixture-tag-output')
			expect(html).to include('Fixture post body.')
		end
	end

	it 'exposes path helpers for source and generated output locations' do
		files = {
			'_layouts' => {
				'default.html' => '<html><body>{{ content }}</body></html>'
			},
			'_posts' => {
				'2026-01-02-paths.md' => <<~MARKDOWN
					---
					layout: default
					permalink: /docs/paths.html
					---
					Path helpers body.
				MARKDOWN
			}
		}

		build_jekyll_site(files: files) do |_site, paths|
			expect(paths.source_path('_posts/2026-01-02-paths.md')).to end_with(File.join('_posts', '2026-01-02-paths.md'))
			expect(paths.output_path('docs/paths.html')).to end_with(File.join('docs', 'paths.html'))
			expect(paths.read_source('_posts/2026-01-02-paths.md')).to include('Path helpers body.')
			expect(paths.read_output('docs/paths.html')).to include('Path helpers body.')
		end
	end
end
