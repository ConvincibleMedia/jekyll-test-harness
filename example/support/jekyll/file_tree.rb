# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module JekyllSpecSupport
	# Writes nested file trees for Jekyll specs.
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
