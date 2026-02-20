# frozen_string_literal: true

require_relative 'support/spec_helper'

RSpec.describe 'Layout asset matching' do
	it 'matches wildcard layout ids using File.fnmatch' do
		build_asset_manager_site do |site, _paths|
			doc = find_post(site, 'docs-intro')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'layouts', 'docs*', 'css')).to include('/assets/css/layouts/docs*/docs.css')
		end
	end

	it 'matches ? and [] patterns for layout packages' do
		extra_config = {
			'assets' => {
				'layouts' => {
					'doc?' => { 'css' => ['docq.css'] },
					'doc[12]' => { 'css' => ['docset.css'] }
				}
			}
		}
		extra_files = {
			'_layouts' => {
				'doc1.html' => asset_manager_docs_layout
			},
			'_posts' => {
				post_filename('doc1', date: '2026-01-03') => post_file(
					front_matter: {
						'layout' => 'doc1',
						'permalink' => '/docs/doc1.html'
					},
					content: 'Doc 1.'
				)
			}
		}

		build_asset_manager_site(extra_config: extra_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'doc1')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'layouts', 'doc?', 'css')).to include('/assets/css/layouts/doc?/docq.css')
			expect(asset_urls(assets, 'layouts', 'doc[12]', 'css')).to include('/assets/css/layouts/doc[12]/docset.css')
		end
	end
end
