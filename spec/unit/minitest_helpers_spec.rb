# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::Minitest::Helpers do
	# Provides a simple host object for exercising helper module methods directly.
	let(:helper_host_class) do
		Class.new do
			include Jekyll::TestHarness::Minitest::Helpers
		end
	end

	it 'delegates merge_jekyll_data to SiteHarness.merge_data' do
		host = helper_host_class.new
		merged = host.merge_jekyll_data({ 'a' => { 'b' => 1 } }, { 'a' => { 'c' => 2 } })
		expect(merged).to eq('a' => { 'b' => 1, 'c' => 2 })
	end

	it 'delegates build_jekyll_site to SiteHarness.with_site' do
		host = helper_host_class.new
		host.build_jekyll_site(default_scaffold: false, files: { 'index.md' => "---\n---\nMinitest helper output\n" }) do |_site, paths|
			expect(paths.read_source('index.md')).to include('Minitest helper output')
		end
	end
end

RSpec.describe Jekyll::TestHarness::Minitest do
	it 'injects helper methods into a supplied Minitest test case class' do
		test_case_class = Class.new
		described_class.configure(test_case_class)

		expect(test_case_class.ancestors).to include(Jekyll::TestHarness::Minitest::Helpers)
	end

	it 'returns the configured test case class' do
		test_case_class = Class.new
		expect(described_class.configure(test_case_class)).to equal(test_case_class)
	end

	it 'raises a clear error when configure is called with an invalid object' do
		expect do
			described_class.configure(Object.new)
		end.to raise_error(ArgumentError, /must respond to #include/)
	end

	it 'uses Minitest::Test as the default class when available' do
		stub_const('Minitest::Test', Class.new)
		configured_class = described_class.configure
		expect(configured_class).to eq(Minitest::Test)
		expect(Minitest::Test.ancestors).to include(Jekyll::TestHarness::Minitest::Helpers)
	end

	it 'raises a clear error when called without Minitest loaded' do
		hide_const('Minitest')

		expect do
			described_class.configure
		end.to raise_error(NameError, /Minitest::Test is not defined/)
	end
end
