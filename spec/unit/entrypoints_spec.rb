# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Library entrypoints' do
	it 'loads the root API entrypoint' do
		expect { require 'jekyll_test_harness' }.not_to raise_error
		expect(defined?(JekyllTestHarness::SiteHarness)).to eq('constant')
		expect(JekyllTestHarness).to respond_to(:install!)
	end

	it 'does not expose a separate RSpec shim entrypoint' do
		expect { require 'jekyll_test_harness/rspec' }.to raise_error(LoadError)
	end

	it 'does not expose a separate Minitest shim entrypoint' do
		expect { require 'jekyll_test_harness/minitest' }.to raise_error(LoadError)
	end
end

