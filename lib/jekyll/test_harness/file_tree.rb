# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module Jekyll
	module TestHarness
		# Writes nested file trees used to construct temporary Jekyll sites.
		module FileTree
			module_function

			# Writes a YAML file to disk, creating parent directories when needed.
			def write_yaml(path, data)
				FileUtils.mkdir_p(File.dirname(path))
				File.write(path, data.to_yaml)
			end

			# Writes a nested hash of files and directories under the supplied root.
			def write(root, files)
				files.each do |relative_path, contents|
					full_path = File.join(root, relative_path.to_s)
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
end
