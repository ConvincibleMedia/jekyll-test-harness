# frozen_string_literal: true

require_relative 'support/spec_helper'

RSpec.describe 'Assets tag rendering' do
	it 'renders CSS and JS assets in the final HTML' do
		build_asset_manager_site do |site, paths|
			doc = find_post(site, 'default')
			expect(doc).not_to be_nil

			html = rendered_output(paths, doc)
			expect(html).to include('data-id="layouts/default"')
			expect(html).to include('href="/assets/css/layouts/default/layout.css"')
			expect(html).to include('href="/assets/css/features/dropdowns/animation.css"')
			expect(html).to include('src="/assets/js/features/dropdowns/drop.js"')
		end
	end

	it 'supports quoted asset types in the tag markup' do
		quoted_layout = <<~HTML
			<!doctype html>
			<html>
				<head>
					{% assets "css" %}
						<link rel="stylesheet" href="{{ asset.url }}">
					{% endassets %}
				</head>
				<body>
					{{ content }}
				</body>
			</html>
		HTML

		extra_config = {
			'assets' => {
				'layouts' => {
					'quoted' => { 'css' => ['layout.css'] }
				}
			}
		}
		extra_files = {
			'_layouts' => { 'quoted.html' => quoted_layout },
			'_posts' => {
				post_filename('quoted', date: '2026-01-03') => post_file(
					front_matter: {
						'layout' => 'quoted',
						'permalink' => '/docs/quoted.html'
					},
					content: 'Quoted layout.'
				)
			}
		}

		build_asset_manager_site(extra_config: extra_config, extra_files: extra_files) do |site, paths|
			doc = find_post(site, 'quoted')
			expect(doc).not_to be_nil

			html = rendered_output(paths, doc)
			expect(html).to include('href="/assets/css/layouts/quoted/layout.css"')
		end
	end

	it 'returns empty output when no assets match the requested type' do
		missing_layout = <<~HTML
			<!doctype html>
			<html>
				<head>
					{% assets img %}
						<img src="{{ asset.url }}">
					{% endassets %}
				</head>
				<body>
					{{ content }}
				</body>
			</html>
		HTML

		extra_config = {
			'assets' => {
				'layouts' => {
					'empty-assets' => { 'css' => ['layout.css'] }
				}
			}
		}
		extra_files = {
			'_layouts' => { 'empty-assets.html' => missing_layout },
			'_posts' => {
				post_filename('empty-tag', date: '2026-01-04') => post_file(
					front_matter: {
						'layout' => 'empty-assets',
						'permalink' => '/docs/empty-tag.html'
					},
					content: 'Empty tag.'
				)
			}
		}

		build_asset_manager_site(extra_config: extra_config, extra_files: extra_files) do |site, paths|
			doc = find_post(site, 'empty-tag')
			expect(doc).not_to be_nil

			html = rendered_output(paths, doc)
			expect(html).not_to include('<img')
		end
	end

	it 'raises a syntax error when the type is missing' do
		expect do
			Liquid::Template.parse('{% assets %}x{% endassets %}')
		end.to raise_error(Liquid::SyntaxError)
	end
end
