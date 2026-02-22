# frozen_string_literal: true

require 'fileutils'
require 'jekyll'

module JekyllTestHarness
	# Builds temporary Jekyll sites for integration-style plugin specs.
	class SiteHarness
		# Builds a site, yields it, then handles temporary directory cleanup.
		def self.with_site(config: {}, files: {}, base_config: {}, base_files: {}, default_scaffold: true, keep_site_on_failure: false)
			raise MissingBlockError, 'SiteHarness.with_site requires a block.' unless block_given?

			TemporaryDirectory.with_dir(prefix: Configuration.temporary_directory_prefix, keep_on_error: keep_site_on_failure) do |temporary_directory_path|
				source_path = File.join(temporary_directory_path, 'site')
				destination_path = File.join(temporary_directory_path, '_site')
				FileUtils.mkdir_p(source_path)

				merged_config = build_config(source_path: source_path, destination_path: destination_path, base_config: base_config, config: config)
				merged_files = build_files(base_files: base_files, files: files, default_scaffold: default_scaffold)

				FileTree.write_yaml(File.join(source_path, '_config.yml'), merged_config)
				FileTree.write(source_path, merged_files)

				site = process_site(merged_config: merged_config, source_path: source_path, destination_path: destination_path)
				yield site, Paths.new(source: source_path, destination: destination_path)
			end
		end

		# Deep-merges hash-like data, replacing scalar and array values from overrides.
		def self.merge_data(base, overrides)
			return deep_clone(overrides) if base.nil?
			return deep_clone(base) if overrides.nil?
			return deep_clone(overrides) unless base.is_a?(Hash) && overrides.is_a?(Hash)

			merged = deep_clone(base)
			overrides.each do |key, value|
				merged[key] = if merged[key].is_a?(Hash) && value.is_a?(Hash)
					merge_data(merged[key], value)
				else
					deep_clone(value)
				end
			end

			merged
		end

		private

		# Builds the final Jekyll configuration written to _config.yml.
		def self.build_config(source_path:, destination_path:, base_config:, config:)
			merged = merge_data(Configuration.default_config(source: source_path, destination: destination_path), base_config || {})
			merge_data(merged, config || {})
		end

		# Builds the final source file tree written into the temporary site source.
		def self.build_files(base_files:, files:, default_scaffold:)
			initial_files = default_scaffold ? Configuration.default_scaffold_files : {}
			merged = merge_data(initial_files, base_files || {})
			merge_data(merged, files || {})
		end

		# Runs Jekyll::Site#process and wraps failures with rich diagnostics.
		def self.process_site(merged_config:, source_path:, destination_path:)
			site = ::Jekyll::Site.new(::Jekyll.configuration(merged_config))
			site.process
			site
		rescue StandardError => raised_error
			raise SiteBuildError.new(
				cause: raised_error,
				source_path: source_path,
				destination_path: destination_path,
				config_snapshot: merge_data({}, merged_config)
			), cause: raised_error
		end

		# Duplicates configuration and file data so callers can mutate safely.
		def self.deep_clone(value)
			case value
			when Hash
				value.each_with_object({}) do |(key, nested_value), clone|
					clone[key] = deep_clone(nested_value)
				end
			when Array
				value.map { |item| deep_clone(item) }
			when String
				value.dup
			else
				value
			end
		end
		private_class_method :build_config, :build_files, :process_site, :deep_clone
	end
end
