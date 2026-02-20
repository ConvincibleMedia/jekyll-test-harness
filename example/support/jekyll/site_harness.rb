# frozen_string_literal: true

require 'fileutils'
require 'jekyll'

require_relative 'file_tree'
require_relative 'temporary_directory'

module JekyllSpecSupport
	# Builds and renders temporary Jekyll sites for specs.
	class SiteHarness
		# Wraps common paths for a built site and provides convenience helpers for reading output files.
		class Paths
			attr_reader :source, :destination

			# Creates a paths helper for a built site. Instantiate only via `with_site`.
			def initialize(source:, destination:)
				@source = source
				@destination = destination
			end

			# Reads a generated file from the build destination using a relative path.
			def read_output(relative_path)
				File.read(File.join(@destination, relative_path))
			end
		end

		# Builds a temporary Jekyll site and yields the site and helper paths to the caller.
		def self.with_site(config: {}, files: {}, base_config: {}, base_files: {})
			raise ArgumentError, 'with_site requires a block' unless block_given?

			TemporaryDirectory.with_dir(prefix: 'jekyll-asset-manager-') do |dir|
				source = File.join(dir, 'site')
				destination = File.join(dir, '_site')
				FileUtils.mkdir_p(source)

				merged_config = merge_data(default_config(source: source, destination: destination), base_config)
				merged_config = merge_data(merged_config, config)
				FileTree.write_yaml(File.join(source, '_config.yml'), merged_config)

				merged_files = merge_data(default_files, base_files)
				merged_files = merge_data(merged_files, files)
				FileTree.write(source, merged_files)

				site = Jekyll::Site.new(Jekyll.configuration(merged_config))
				site.process

				yield site, Paths.new(source: source, destination: destination)
			end
		end

		# Deep-merges nested hashes while favouring values from the second hash.
		def self.merge_data(base, overrides)
			deep_merge_hashes(base, overrides)
		end

		# Provides the default site configuration used by the harness.
		def self.default_config(source:, destination:)
			{
				'source' => source,
				'destination' => destination,
				'quiet' => true
			}
		end
		private_class_method :default_config

		# Provides the default site files used by the harness.
		def self.default_files
			{
				'_layouts' => {
					'default.html' => <<~HTML
						<!doctype html>
						<html>
							<head>
								<meta charset="utf-8">
								<title>Test Site</title>
							</head>
							<body>
								{{ content }}
							</body>
						</html>
					HTML
				},
				'index.md' => <<~MD
					---
					layout: default
					---
					Hello from the test site.
				MD
			}
		end
		private_class_method :default_files

		# Deep-merges hashes recursively; non-hash values are replaced by overrides.
		def self.deep_merge_hashes(base, overrides)
			return overrides if base.nil?
			return base if overrides.nil?

			base.merge(overrides) do |_key, left, right|
				if left.is_a?(Hash) && right.is_a?(Hash)
					deep_merge_hashes(left, right)
				else
					right
				end
			end
		end
		private_class_method :deep_merge_hashes
	end
end
