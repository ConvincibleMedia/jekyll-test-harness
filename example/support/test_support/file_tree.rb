# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'yaml'

# Provides general-purpose helpers for creating temporary directories and writing file trees in specs.
module TestSupport
	# Creates and cleans up a temporary directory for the caller.
	module TemporaryDirectory
		# Yields a temporary directory path and ensures it is removed afterwards.
		def self.with_dir(prefix: 'jekyll-asset-manager-')
			Dir.mktmpdir(prefix) { |dir| yield dir }
		end
	end

	# Writes nested file hashes to disk, allowing specs to describe file trees succinctly.
	module FileTree
		# Writes a YAML file to the specified path.
		def self.write_yaml(path, data)
			File.write(path, data.to_yaml)
		end

		# Writes a nested hash of files into the target root directory.
		def self.write(root, files)
			files.each do |relative_path, contents|
				full_path = File.join(root, relative_path)
				if contents.is_a?(Hash)
					FileUtils.mkdir_p(full_path)
					write(full_path, contents)
				else
					FileUtils.mkdir_p(File.dirname(full_path))
					File.write(full_path, contents.to_s)
				end
			end
		end
	end
end
