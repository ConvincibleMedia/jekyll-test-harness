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

	# Builds consistent, actionable validation messages for invalid harness usage.
	module ValidationMessages
		module_function

		# Describes a runtime value with a class name and a safely-truncated inspect payload.
		def describe_value(value)
			inspected_value = value.inspect
			inspected_value = "#{inspected_value[0, 157]}..." if inspected_value.length > 160
			"#{inspected_value} (#{value.class})"
		end

		# Builds an error message for arguments that do not match the expected type.
		def type_error(argument_name:, expected:, value:, usage: nil)
			append_usage("#{argument_name} must be #{expected}. Received #{describe_value(value)}.", usage)
		end

		# Builds an error message for unsupported option values.
		def unsupported_value(argument_name:, value:, supported_values:, usage: nil)
			supported_description = supported_values.map(&:inspect).join(', ')
			append_usage("Unsupported value for #{argument_name}: #{describe_value(value)}. Supported values: #{supported_description}.", usage)
		end

		# Builds an error message for APIs that require a block.
		def missing_block(method_name:, usage:)
			"#{method_name} requires a block. Usage: #{usage}."
		end

		# Appends usage guidance only when it is present.
		def append_usage(message, usage)
			return message if usage.nil? || usage.to_s.strip.empty?

			"#{message} #{usage}"
		end
	end
end
