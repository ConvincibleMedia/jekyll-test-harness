# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness do
	it 'installs helper methods into a supplied Minitest test case class' do
		test_case_class = Class.new
		described_class.install!(:minitest, minitest_test_case: test_case_class)

		expect(test_case_class.ancestors).to include(JekyllTestHarness::Helpers)
	end

	it 'returns the configured Minitest test case class' do
		test_case_class = Class.new
		expect(described_class.install!(:minitest, minitest_test_case: test_case_class)).to equal(test_case_class)
	end

	it 'raises a clear error when Minitest target is invalid' do
		expect do
			described_class.install!(:minitest, minitest_test_case: Object.new)
		end.to raise_error(ArgumentError, /must respond to #include/)
	end

	it 'uses Minitest::Test as the default class when available' do
		stub_const('Minitest::Test', Class.new)
		configured_class = described_class.install!(:minitest)
		expect(configured_class).to eq(Minitest::Test)
		expect(Minitest::Test.ancestors).to include(JekyllTestHarness::Helpers)
	end

	it 'raises a clear error when explicit Minitest installation is requested but Minitest is unavailable' do
		allow(described_class).to receive(:minitest_available?).and_return(false)

		expect do
			described_class.install!(:minitest)
		end.to raise_error(NameError, /Minitest::Test is not available/)
	end

	it 'auto-detects Minitest when it is the only loaded framework' do
		allow(described_class).to receive(:available_frameworks).and_return([:minitest])
		test_case_class = Class.new

		returned_class = described_class.install!(:auto, minitest_test_case: test_case_class)

		expect(returned_class).to equal(test_case_class)
		expect(test_case_class.ancestors).to include(JekyllTestHarness::Helpers)
	end
end

