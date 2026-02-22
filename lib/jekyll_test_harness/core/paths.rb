# frozen_string_literal: true

module JekyllTestHarness
	# Exposes output-first helpers for a built site while still supporting source inspection.
	class Files
		attr_reader :dir, :source_dir

		# Initialises helpers with output and source roots.
		def initialize(source_dir:, dir:)
			@source_dir = source_dir
			@dir = dir
		end

		# Returns the absolute path to a generated output file.
		def path(relative_path)
			resolve_relative_path(dir, relative_path)
		end

		# Reads a generated file from the output directory.
		def read(relative_path)
			File.read(path(relative_path))
		end

		# Lists generated output files as paths relative to the output directory.
		def list(root = nil)
			list_relative_files(dir, root)
		end

		# Returns the absolute path to a source file in the temporary site.
		def source_path(relative_path)
			resolve_relative_path(source_dir, relative_path)
		end

		# Reads a source file from the source directory.
		def source_read(relative_path)
			File.read(source_path(relative_path))
		end

		# Lists source files as paths relative to the source directory.
		def source_list(root = nil)
			list_relative_files(source_dir, root)
		end

		private

		# Resolves a relative path and prevents directory traversal outside the root.
		def resolve_relative_path(root_path, relative_path)
			raise ArgumentError, 'relative_path must not be absolute.' if relative_path.to_s.start_with?('/')
			raise ArgumentError, 'relative_path must not be absolute.' if relative_path.to_s.match?(/\A[A-Za-z]:[\\\/]/)

			resolved_path = File.expand_path(File.join(root_path, relative_path.to_s))
			expanded_root = File.expand_path(root_path)
			return resolved_path if resolved_path == expanded_root || resolved_path.start_with?("#{expanded_root}#{File::SEPARATOR}")

			raise ArgumentError, "relative_path escapes the site root: #{relative_path}"
		end

		# Lists file paths for either the root or a subfolder, always returned relative to root_path.
		def list_relative_files(root_path, list_root)
			search_root = list_root.nil? ? root_path : resolve_relative_path(root_path, list_root)
			return [] unless File.exist?(search_root)

			paths = if File.file?(search_root)
				[search_root]
			else
				Dir.glob(File.join(search_root, '**', '*')).select { |candidate_path| File.file?(candidate_path) }
			end
			paths.map { |absolute_path| absolute_path.sub("#{File.expand_path(root_path)}#{File::SEPARATOR}", '').tr('\\', '/') }.sort
		end
	end

	# Provides a backwards-compatible constant alias for older code paths.
	Paths = Files
end
