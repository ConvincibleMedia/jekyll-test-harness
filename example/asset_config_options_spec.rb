# frozen_string_literal: true

require_relative 'support/spec_helper'

RSpec.describe 'Asset configuration options' do
	it 'supports custom asset types' do
		custom_config = {
			'assets' => {
				'types' => ['css', 'svg'],
				'basepath' => '/assets/:type/:group/:package',
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'icons' => {
					'logo' => { 'svg' => ['logo.svg'] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('icon', date: '2026-01-01') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/icon.html',
						'assets' => { 'icons' => ['logo'] }
					},
					content: 'Icon document.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: custom_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'icon')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'icons', 'logo', 'svg')).to include('/assets/svg/icons/logo/logo.svg')
		end
	end

	it 'builds URLs without a basepath when it is blank' do
		blank_config = {
			'assets' => {
				'basepath' => '',
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('blank-base', date: '2026-01-02') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/blank-base.html'
					},
					content: 'Blank basepath.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: blank_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'blank-base')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'layouts', 'default', 'css')).to include('/layout.css')
		end
	end

	it 'respects group and package folder overrides' do
		override_config = {
			'assets' => {
				'basepath' => '/assets/:type/:group/:package',
				'folders' => {
					'separator' => '/',
					'core' => 'shared',
					'core/base' => 'root'
				},
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'core' => {
					'base' => { 'css' => ['base.css'] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('overrides', date: '2026-01-03') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/overrides.html',
						'assets' => { 'core' => ['base'] }
					},
					content: 'Overrides.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: override_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'overrides')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'core', 'base', 'css')).to include('/assets/css/shared/root/base.css')
		end
	end

	it 'collapses group folders when configured to be empty' do
		collapse_config = {
			'assets' => {
				'basepath' => '/assets/:type/:group/:package',
				'folders' => {
					'features' => ''
				},
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'features' => {
					'dropdowns' => { 'css' => ['animation.css'] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('collapse', date: '2026-01-04') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/collapse.html',
						'assets' => { 'features' => ['dropdowns'] }
					},
					content: 'Collapse.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: collapse_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'collapse')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'features', 'dropdowns', 'css')).to include('/assets/css/dropdowns/animation.css')
		end
	end

	it 'honours folder overrides when a custom separator is configured' do
		separator_config = {
			'assets' => {
				'basepath' => '/assets/:type/:group/:package',
				'folders' => {
					'separator' => ':',
					'core:base' => 'root'
				},
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'core' => {
					'base' => { 'css' => ['base.css'] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('separator', date: '2026-01-05') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/separator.html',
						'assets' => { 'core' => ['base'] }
					},
					content: 'Separator.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: separator_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'separator')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'core', 'base', 'css')).to include('/assets/css/core/root/base.css')
		end
	end

	it 'expands true asset entries to the package name and type' do
		shorthand_config = {
			'assets' => {
				'basepath' => '/assets/:type/:group/:package',
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'features' => {
					'dropdowns' => { 'css' => [true] }
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('shorthand', date: '2026-01-06') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/shorthand.html',
						'assets' => { 'features' => ['dropdowns'] }
					},
					content: 'Shorthand.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: shorthand_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'shorthand')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			expect(asset_urls(assets, 'features', 'dropdowns', 'css')).to include('/assets/css/features/dropdowns/dropdowns.css')
		end
	end

	it 'preserves absolute and root URLs while expanding relative ones' do
		absolute_config = {
			'assets' => {
				'basepath' => '/assets/:type/:group/:package',
				'layouts' => {
					'default' => { 'css' => ['layout.css'] }
				},
				'scripts' => {
					'app' => {
						'js' => ['https://cdn.example/app.js', '/local/app.js', 'relative.js']
					}
				}
			}
		}
		extra_files = {
			'_posts' => {
				post_filename('absolute', date: '2026-01-07') => post_file(
					front_matter: {
						'layout' => 'default',
						'permalink' => '/docs/absolute.html',
						'assets' => { 'scripts' => ['app'] }
					},
					content: 'Absolute.'
				)
			}
		}

		build_asset_manager_site(use_base: false, extra_config: absolute_config, extra_files: extra_files) do |site, _paths|
			doc = find_post(site, 'absolute')
			expect(doc).not_to be_nil

			assets = doc.data['assets']
			urls = asset_urls(assets, 'scripts', 'app', 'js')
			expect(urls).to include('https://cdn.example/app.js')
			expect(urls).to include('/local/app.js')
			expect(urls).to include('/assets/js/scripts/app/relative.js')
		end
	end
end
