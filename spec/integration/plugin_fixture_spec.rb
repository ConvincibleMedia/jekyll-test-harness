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

		jekyll_build(files: files) do |site, files|
			document = site.collections.fetch('posts').docs.find { |doc| doc.basename_without_ext.end_with?('fixture-post') }
			expect(document.data['fixture_hook_marker']).to eq('hooked-by-fixture')

			html = files.read('docs/fixture-post.html')
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

		jekyll_build(files: files) do |_site, files|
			expect(files.source_path('_posts/2026-01-02-paths.md')).to end_with(File.join('_posts', '2026-01-02-paths.md'))
			expect(files.path('docs/paths.html')).to end_with(File.join('docs', 'paths.html'))
			expect(files.source_read('_posts/2026-01-02-paths.md')).to include('Path helpers body.')
			expect(files.read('docs/paths.html')).to include('Path helpers body.')
		end
	end
end
