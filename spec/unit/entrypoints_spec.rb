# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Library entrypoints' do
	it 'loads the root API entrypoint' do
		expect { require 'jekyll_test_harness' }.not_to raise_error
		expect(defined?(Jekyll::TestHarness::SiteHarness)).to eq('constant')
	end

	it 'loads the RSpec entrypoint' do
		expect { require 'jekyll_test_harness/rspec' }.not_to raise_error
		expect(defined?(Jekyll::TestHarness::RSpec)).to eq('constant')
	end

	it 'loads the Minitest entrypoint' do
		expect { require 'jekyll_test_harness/minitest' }.not_to raise_error
		expect(defined?(Jekyll::TestHarness::Minitest)).to eq('constant')
	end
end
