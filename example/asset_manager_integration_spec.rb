# frozen_string_literal: true

require_relative 'support/spec_helper'

RSpec.describe Jekyll::Plugins::AssetManager::Hooks::DocumentPreRender do
	it 'resolves layout and front-matter assets into page data' do
		build_asset_manager_site do |site, _paths|
			doc = find_post(site, 'default')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(assets).to be_a(Hash)

			expect(asset_urls(assets, 'layouts', 'default', 'css')).to include('/assets/css/layouts/default/layout.css')
			expect(asset_urls(assets, 'features', 'dropdowns', 'css')).to include('/assets/css/features/dropdowns/animation.css')
			expect(asset_urls(assets, 'features', 'dropdowns', 'js')).to include('/assets/js/features/dropdowns/drop.js')
			expect(asset_urls(assets, 'core', 'base', 'css')).to include('/assets/css/core/base/base.css')
		end
	end

	it 'accepts front-matter packages provided as a string' do
		extra_files = {
			'_posts' => {
				post_filename('core-only', date: '2026-01-03') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/core-only.html',
						'assets' => { 'core' => 'base' }
					},
					content: 'Core only.'
				)
			}
		}

		build_asset_manager_site(extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'core-only')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'core', 'base', 'css')).to include('/assets/css/core/base/base.css')
		end
	end

	it 'ignores non-hash front-matter assets but keeps layout assets' do
		extra_files = {
			'_posts' => {
				post_filename('invalid-assets', date: '2026-01-04') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/invalid-assets.html',
						'assets' => 'core/base'
					},
					content: 'Invalid assets.'
				)
			}
		}

		build_asset_manager_site(extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'invalid-assets')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'layouts', 'default', 'css')).to include('/assets/css/layouts/default/layout.css')
			expect(assets.key?('features')).to be(false)
			expect(assets.key?('core')).to be(false)
		end
	end

	it 'falls back to layout assets when front matter references an unknown group' do
		extra_files = {
			'_posts' => {
				post_filename('unknown-group', date: '2026-01-05') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/unknown-group.html',
						'assets' => { 'missing' => ['nope'], 'features' => ['dropdowns'] }
					},
					content: 'Unknown group.'
				)
			}
		}

		build_asset_manager_site(extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'unknown-group')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'layouts', 'default', 'css')).to include('/assets/css/layouts/default/layout.css')
			expect(asset_urls(assets, 'features', 'dropdowns', 'css')).to include('/assets/css/features/dropdowns/animation.css')
			expect(assets.key?('missing')).to be(false)
		end
	end

	it 'uses front-matter assets when no layout is specified' do
		extra_files = {
			'_posts' => {
				post_filename('front-only', date: '2026-01-06') => post_file(
					front_matter: {
						'layout' => nil,
						'permalink' => '/docs/front-only.html',
						'assets' => { 'core' => ['base'] }
					},
					content: 'Front matter only.'
				)
			}
		}

		build_asset_manager_site(extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'front-only')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'core', 'base', 'css')).to include('/assets/css/core/base/base.css')
			expect(assets.key?('layouts')).to be(false)
		end
	end

	it 'does not set assets when no layout or front matter assets are present' do
		extra_files = {
			'_posts' => {
				post_filename('empty-assets', date: '2026-01-07') => post_file(
					front_matter: {
						'layout' => nil,
						'permalink' => '/docs/empty-assets.html'
					},
					content: 'Empty assets.'
				)
			}
		}

		build_asset_manager_site(extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'empty-assets')
			expect(doc).not_to be_nil

			expect(doc.data.key?('assets')).to be(false)
		end
	end
end
