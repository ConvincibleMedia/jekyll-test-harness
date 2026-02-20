# frozen_string_literal: true

require_relative 'support/spec_helper'

RSpec.describe Jekyll::Plugins::AssetManager::Hooks::SitePreRender do
	it 'initialises AssetDB from the Jekyll configuration' do
		build_asset_manager_site do |_site, _paths|
			db = Jekyll::Plugins::AssetManager.db
			expect(db).not_to be_nil
			group_ids = db.groups.map { |group| group.id.to_s }
			expect(group_ids).to include('layouts', 'features', 'core')
		end
	end

	it 'creates an empty AssetDB when no assets config is provided' do
		build_asset_manager_site(use_base: false) do |_site, _paths|
			db = Jekyll::Plugins::AssetManager.db
			expect(db).not_to be_nil
			expect(db.groups).to be_empty
			expect(db.basepath).to eq('')
		end
	end

	it 'raises when the assets config is invalid' do
		invalid_config = {
			'assets' => {
				'css' => {
					'bad' => { 'css' => ['bad.css'] }
				}
			}
		}

		expect do
			build_asset_manager_site(use_base: false, extra_config: invalid_config) { |_site, _paths| }
		end.to raise_error(AssetDB::Errors::InvalidIdentifierError)
	end
end
