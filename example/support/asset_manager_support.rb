# frozen_string_literal: true

require 'yaml'

# Provides fixtures and helper methods for Asset Manager specs.
module AssetManagerSpecSupport
	# Defines reusable config and file fixtures for Asset Manager specs.
	module Fixtures
		# Returns the default Asset Manager configuration used by most specs.
		def asset_manager_base_config
			{
				'assets' => {
					'basepath' => '/assets/:type/:group/:package',
					'layouts' => {
						'default' => { 'css' => ['layout.css'] },
						'docs*' => { 'css' => ['docs.css'] }
					},
					'features' => {
						'dropdowns' => {
							'css' => ['animation.css'],
							'js' => ['drop.js'],
							'core' => ['base']
						}
					},
					'core' => {
						'base' => { 'css' => ['base.css'] }
					}
				}
			}
		end

		# Returns a default layout that renders both CSS and JS assets.
		def asset_manager_default_layout
			<<~HTML
				<!doctype html>
				<html>
					<head>
						{% assets css %}
							<link rel="stylesheet" data-id="{{ asset.id }}" href="{{ asset.url }}">
						{% endassets %}
					</head>
					<body>
						{{ content }}
						{% assets js %}
							<script data-id="{{ asset.id }}" src="{{ asset.url }}"></script>
						{% endassets %}
					</body>
				</html>
			HTML
		end

		# Returns a layout used for testing layout glob matches.
		def asset_manager_docs_layout
			<<~HTML
				<!doctype html>
				<html>
					<head>
						{% assets css %}
							<link rel="stylesheet" data-id="{{ asset.id }}" href="{{ asset.url }}">
						{% endassets %}
					</head>
					<body>
						{{ content }}
					</body>
				</html>
			HTML
		end

		# Returns the default file tree used by most specs.
		def asset_manager_base_files
			{
				'_layouts' => {
					'default.html' => asset_manager_default_layout,
					'docs-intro.html' => asset_manager_docs_layout
				},
				'_posts' => {
					post_filename('default', date: '2026-01-01') => post_file(
						front_matter: {
							'layout' => 'default',
							'permalink' => '/docs/default.html',
							'assets' => { 'features' => ['dropdowns'] }
						},
						content: 'Default document.'
					),
					post_filename('docs-intro', date: '2026-01-02') => post_file(
						front_matter: {
							'layout' => 'docs-intro',
							'permalink' => '/docs/docs-intro.html'
						},
						content: 'Docs intro document.'
					)
				}
			}
		end

		# Builds a post filename using the provided date and slug.
		def post_filename(slug, date: '2026-01-01')
			"#{date}-#{slug}.md"
		end

		# Builds a post file with YAML front matter and body content.
		def post_file(front_matter:, content:)
			"#{front_matter_block(front_matter)}#{content}\n"
		end

		# Builds a YAML front matter block from a hash.
		def front_matter_block(front_matter)
			yaml = front_matter.to_yaml.sub(/\A---\s*\n?/, '')
			"---\n#{yaml}---\n"
		end
	end

	# Provides helper methods for building and inspecting Asset Manager test sites.
	module Helpers
		# Builds a Jekyll site for Asset Manager specs, optionally merging in extra config and files.
		def build_asset_manager_site(extra_config: {}, extra_files: {}, use_base: true)
			config = use_base ? JekyllSpecSupport::SiteHarness.merge_data(asset_manager_base_config, extra_config) : extra_config
			files = use_base ? JekyllSpecSupport::SiteHarness.merge_data(asset_manager_base_files, extra_files) : extra_files
			JekyllSpecSupport::SiteHarness.with_site(config: config, files: files) { |site, paths| yield site, paths }
		end

		# Finds a post document by slug or basename.
		def find_post(site, slug)
			posts = site.collections['posts']&.docs || []
			posts.find do |doc|
				doc.data['slug'] == slug || doc.basename_without_ext == slug || doc.basename_without_ext.end_with?("-#{slug}")
			end
		end

		# Extracts a flat array of URLs from the assets hash for assertions.
		def asset_urls(assets, group_id, package_id, type)
			Array(assets.dig(group_id, package_id, type)).map { |asset| asset['url'] }
		end

		# Reads rendered output for a document from the build destination.
		def rendered_output(paths, doc)
			paths.read_output(doc.url.sub(%r{^/}, ''))
		end
	end
end
