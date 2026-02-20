# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::RSpec::Helpers do
	# Provides a simple host object for exercising helper module methods directly.
	let(:helper_host_class) do
		Class.new do
			include Jekyll::TestHarness::RSpec::Helpers
		end
	end

	it 'delegates merge_jekyll_data to SiteHarness.merge_data' do
		host = helper_host_class.new
		merged = host.merge_jekyll_data({ 'a' => { 'b' => 1 } }, { 'a' => { 'c' => 2 } })
		expect(merged).to eq('a' => { 'b' => 1, 'c' => 2 })
	end

	it 'delegates build_jekyll_site to SiteHarness.with_site' do
		host = helper_host_class.new
		host.build_jekyll_site(default_scaffold: false, files: { 'index.md' => "---\n---\nHelper output\n" }) do |_site, paths|
			expect(paths.read_source('index.md')).to include('Helper output')
		end
	end
end
