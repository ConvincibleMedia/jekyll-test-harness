# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::Helpers do
	# Provides a simple host object for exercising helper module methods directly.
	let(:helper_host_class) do
		Class.new do
			include JekyllTestHarness::Helpers
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

RSpec.describe JekyllTestHarness do
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

	it 'installs helpers into the supplied RSpec configuration object' do
		configuration = IncludeRecorder.new
		returned_configuration = described_class.install!(:rspec, rspec_configuration: configuration)

		expect(configuration.included_modules).to include(JekyllTestHarness::Helpers)
		expect(returned_configuration).to equal(configuration)
	end

	it 'supports configure as an alias for install!' do
		configuration = IncludeRecorder.new
		returned_configuration = described_class.configure(:rspec, rspec_configuration: configuration)

		expect(configuration.included_modules).to include(JekyllTestHarness::Helpers)
		expect(returned_configuration).to equal(configuration)
	end

	it 'uses the global RSpec configuration when no target is supplied' do
		configuration = described_class.install!(:rspec)
		expect(configuration).to equal(::RSpec.configuration)
	end

	it 'raises a clear error when RSpec configuration target is invalid' do
		expect do
			described_class.install!(:rspec, rspec_configuration: Object.new)
		end.to raise_error(ArgumentError, /must respond to #include/)
	end

	it 'raises a clear error when explicit RSpec installation is requested but RSpec is unavailable' do
		allow(described_class).to receive(:rspec_available?).and_return(false)

		expect do
			described_class.install!(:rspec)
		end.to raise_error(NameError, /RSpec is not available/)
	end

	it 'auto-detects RSpec when it is the only loaded framework' do
		allow(described_class).to receive(:available_frameworks).and_return([:rspec])
		configuration = IncludeRecorder.new

		returned_configuration = described_class.install!(:auto, rspec_configuration: configuration)

		expect(returned_configuration).to equal(configuration)
		expect(configuration.included_modules).to include(JekyllTestHarness::Helpers)
	end

	it 'raises clear guidance when auto detection finds no framework' do
		allow(described_class).to receive(:available_frameworks).and_return([])

		expect do
			described_class.install!
		end.to raise_error(NameError, /No supported test framework is loaded/)
	end

	it 'raises clear guidance when auto detection finds multiple frameworks' do
		allow(described_class).to receive(:available_frameworks).and_return(%i[rspec minitest])

		expect do
			described_class.install!
		end.to raise_error(ArgumentError, /Multiple supported frameworks are loaded/)
	end

	it 'raises a clear error for unsupported framework values' do
		expect do
			described_class.install!(:unknown)
		end.to raise_error(ArgumentError, /Unsupported framework/)
	end
end

