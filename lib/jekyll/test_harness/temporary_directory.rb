# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module Jekyll
	module TestHarness
		# Manages temporary directories with optional retention on failure.
		module TemporaryDirectory
			module_function

			# Yields a temporary directory and removes it afterwards unless retention is requested.
			def with_dir(prefix: Configuration.temporary_directory_prefix, keep_on_error: false)
				raise MissingBlockError, 'TemporaryDirectory.with_dir requires a block.' unless block_given?

				temporary_directory_path = Dir.mktmpdir(prefix)
				yield temporary_directory_path
			ensure
				directory_exists = !temporary_directory_path.nil? && File.exist?(temporary_directory_path)
				keep_failed_directory = keep_on_error && !$ERROR_INFO.nil?
				FileUtils.remove_entry(temporary_directory_path) if directory_exists && !keep_failed_directory
			end
		end
	end
end
