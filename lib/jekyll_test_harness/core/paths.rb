# frozen_string_literal: true

module JekyllTestHarness
	# Provides path and file-reading helpers for a built temporary site.
	class Paths
		attr_reader :source, :destination

		# Initialises helpers with the temporary source and destination roots.
		def initialize(source:, destination:)
			@source = source
			@destination = destination
		end

		# Returns the absolute path to a generated output file.
		def output_path(relative_path)
			resolve_relative_path(destination, relative_path)
		end

		# Returns the absolute path to a source file in the temporary site.
		def source_path(relative_path)
			resolve_relative_path(source, relative_path)
		end

		# Reads a generated file from the destination directory.
		def read_output(relative_path)
			File.read(output_path(relative_path))
		end

		# Reads a source file from the source directory.
		def read_source(relative_path)
			File.read(source_path(relative_path))
		end

		private

		# Resolves a relative path and prevents directory traversal outside the root.
		def resolve_relative_path(root_path, relative_path)
			raise ArgumentError, 'relative_path must not be absolute.' if relative_path.to_s.start_with?('/')
			raise ArgumentError, 'relative_path must not be absolute.' if relative_path.to_s.match?(/\A[A-Za-z]:[\\\/]/)

			resolved_path = File.expand_path(File.join(root_path, relative_path.to_s))
			expanded_root = File.expand_path(root_path)
			return resolved_path if resolved_path.start_with?("#{expanded_root}#{File::SEPARATOR}") || resolved_path == expanded_root

			raise ArgumentError, "relative_path escapes the site root: #{relative_path}"
		end
	end
end
