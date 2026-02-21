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

RSpec.describe Jekyll::TestHarness::RSpec do
	# Records modules passed to include so we can verify configure wiring.
	class IncludeRecorder
		attr_reader :included_modules

		def initialize
			@included_modules = []
		end

		def include(module_reference)
			@included_modules << module_reference
		end
	end

	it 'injects helper methods into the supplied RSpec configuration object' do
		configuration = IncludeRecorder.new
		returned_configuration = described_class.configure(configuration)

		expect(configuration.included_modules).to include(Jekyll::TestHarness::RSpec::Helpers)
		expect(returned_configuration).to equal(configuration)
	end

	it 'uses the global RSpec configuration when none is supplied' do
		configuration = described_class.configure
		expect(configuration).to equal(::RSpec.configuration)
	end

	it 'raises a clear error when configure is called with an invalid object' do
		expect do
			described_class.configure(Object.new)
		end.to raise_error(ArgumentError, /must respond to #include/)
	end

	it 'raises a clear error when the default RSpec configuration is unavailable' do
		allow(::RSpec).to receive(:respond_to?).and_call_original
		allow(::RSpec).to receive(:respond_to?).with(:configuration).and_return(false)

		expect do
			described_class.configure
		end.to raise_error(NameError, /RSpec is not available/)
	end
end
