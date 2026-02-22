# frozen_string_literal: true

module JekyllTestHarness
	# Base error class for all harness-specific failures.
	class Error < StandardError
	end

	# Raised when a block-based API is called without a block.
	class MissingBlockError < Error
		# Creates a clear error message for missing block usage.
		def initialize(message = 'This method requires a block.')
			super(message)
		end
	end

	# Wraps Jekyll build failures with context to help debugging.
	class SiteBuildError < Error
		attr_reader :source_path, :destination_path, :config_snapshot, :original_error

		# Captures build context and the original exception that failed the build.
		def initialize(cause:, source_path:, destination_path:, config_snapshot:)
			@original_error = cause
			@source_path = source_path
			@destination_path = destination_path
			@config_snapshot = config_snapshot
			super(build_message)
			set_backtrace(cause.backtrace)
		end

		private

		# Builds a diagnostic message that can be shown directly in failing specs.
		def build_message
			[
				"Jekyll site build failed: #{original_error.class}: #{original_error.message}",
				"Source path: #{source_path}",
				"Destination path: #{destination_path}",
				"Config snapshot: #{config_snapshot.inspect}",
				'Hint: call JekyllTestHarness.install!(..., failures: :keep) to retain failed temporary sites for debugging.'
			].join("\n")
		end
	end
end
