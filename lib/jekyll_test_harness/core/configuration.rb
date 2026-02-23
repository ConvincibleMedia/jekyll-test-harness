# frozen_string_literal: true

require 'pathname'

module JekyllTestHarness
	# Stores runtime harness settings and shared defaults used by SiteHarness.
	module Configuration
		DEFAULT_FAILURE_MODE = :clean
		SUPPORTED_FAILURE_MODES = %i[clean keep].freeze
		TEMPORARY_DIRECTORY_PREFIX = 'jekyll-test-harness'.freeze

		module_function

		# Returns the baseline Jekyll configuration for a temporary site.
		def default_config(source:, destination:)
			{
				'source' => source,
				'destination' => destination,
				'quiet' => true,
				'incremental' => false
			}
		end

		# Applies runtime settings for failure handling and site root location.
		def configure_runtime!(failures:, output:, project_root:)
			@failure_mode = normalise_failure_mode(failures)
			@project_root = File.expand_path((project_root || Dir.pwd).to_s)
			@output = normalise_output(output, @project_root)
		end

		# Resets runtime settings to defaults.
		def reset_runtime!
			configure_runtime!(failures: DEFAULT_FAILURE_MODE, output: nil, project_root: Dir.pwd)
		end

		# Returns the configured behaviour for failed Jekyll builds.
		def failure_mode
			@failure_mode || DEFAULT_FAILURE_MODE
		end

		# Returns true when failed build directories should be kept for debugging.
		def keep_failures?
			failure_mode == :keep
		end

		# Exposes the temporary directory prefix used for unnamed fallback directories.
		def temporary_directory_prefix
			TEMPORARY_DIRECTORY_PREFIX
		end

		# Returns the project root captured during install!.
		def project_root
			@project_root || Dir.pwd
		end

		# Returns the configured base directory for build output roots, or nil for system temp.
		def output
			@output
		end

		# Validates and normalises failure mode values.
		def normalise_failure_mode(failures)
			selected_failures = failures.nil? ? DEFAULT_FAILURE_MODE : failures
			normalised_failures = normalise_symbol_option(
				option_name: 'failures',
				value: selected_failures,
				usage: 'Use `failures: :clean` (default) or `failures: :keep`.'
			)
			return normalised_failures if SUPPORTED_FAILURE_MODES.include?(normalised_failures)

			raise ArgumentError, ValidationMessages.unsupported_value(
				argument_name: 'failures',
				value: failures,
				supported_values: SUPPORTED_FAILURE_MODES,
				usage: 'Use `failures: :clean` (default) or `failures: :keep`.'
			)
		end
		private_class_method :normalise_failure_mode

		# Expands custom output roots relative to project root.
		def normalise_output(output, project_root)
			return nil if output.nil?

			output_path = normalise_path_argument(
				argument_name: 'output',
				value: output,
				usage: "Use `nil` for system temp, a relative String like `'tmp/jekyll-sites'`, or an absolute path."
			)
			raise ArgumentError, '`output` must not be empty.' if output_path.strip.empty?

			return File.expand_path(output_path) if Pathname.new(output_path).absolute?

			File.expand_path(output_path, project_root)
		end
		private_class_method :normalise_output

		# Normalises Symbol/String option values and rejects invalid input types.
		def normalise_symbol_option(option_name:, value:, usage:)
			return value if value.is_a?(Symbol)
			return value.strip.to_sym if value.is_a?(String) && !value.strip.empty?

			raise ArgumentError, ValidationMessages.type_error(argument_name: option_name, expected: 'a Symbol or non-empty String', value: value, usage: usage)
		end
		private_class_method :normalise_symbol_option

		# Normalises path-like arguments and rejects unsupported input types.
		def normalise_path_argument(argument_name:, value:, usage:)
			return value if value.is_a?(String)
			return value.to_path.to_s if value.respond_to?(:to_path)

			raise ArgumentError, ValidationMessages.type_error(argument_name: argument_name, expected: 'a String path or Pathname', value: value, usage: usage)
		end
		private_class_method :normalise_path_argument
	end
end

JekyllTestHarness::Configuration.reset_runtime!
