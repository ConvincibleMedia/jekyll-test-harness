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
end
