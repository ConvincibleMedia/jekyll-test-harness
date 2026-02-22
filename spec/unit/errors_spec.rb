# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness do
	describe JekyllTestHarness::MissingBlockError do
		it 'uses a clear default message' do
			expect(described_class.new.message).to eq('This method requires a block.')
		end

		it 'allows overriding the message' do
			expect(described_class.new('custom message').message).to eq('custom message')
		end
	end

	describe JekyllTestHarness::SiteBuildError do
		it 'captures the original error, context attributes, and diagnostic message' do
			cause = RuntimeError.new('boom')
			cause.set_backtrace(['test_backtrace_line'])
			error = described_class.new(
				cause: cause,
				source_path: '/tmp/source',
				destination_path: '/tmp/destination',
				config_snapshot: { 'quiet' => true }
			)

			expect(error.original_error).to equal(cause)
			expect(error.source_path).to eq('/tmp/source')
			expect(error.destination_path).to eq('/tmp/destination')
			expect(error.config_snapshot).to eq('quiet' => true)
			expect(error.message).to include('Jekyll site build failed: RuntimeError: boom')
			expect(error.message).to include('Source path: /tmp/source')
			expect(error.message).to include('Destination path: /tmp/destination')
			expect(error.message).to include("Config snapshot: {\"quiet\" => true}")
			expect(error.message).to include('failures: :keep')
			expect(error.backtrace).to eq(['test_backtrace_line'])
		end
	end
end

