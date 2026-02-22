# frozen_string_literal: true

require 'fileutils'
require 'jekyll'

module JekyllTestHarness
	# Builds temporary Jekyll sites for integration-style plugin specs.
	class SiteHarness
		# Builds a site, yields it, then handles temporary directory cleanup.
		def self.with_site(config: {}, files: {}, context: nil)
			raise MissingBlockError, 'SiteHarness.with_site requires a block.' unless block_given?

			TemporaryDirectory.with_dir(
				prefix: Configuration.temporary_directory_prefix,
				root_directory: Configuration.output,
				label: infer_build_label(context),
				keep_on_error: Configuration.keep_failures?
			) do |temporary_directory_path|
				source_path = File.join(temporary_directory_path, 'site')
				destination_path = File.join(temporary_directory_path, '_site')
				FileUtils.mkdir_p(source_path)

				merged_config = build_config(source_path: source_path, destination_path: destination_path, config: config)
				merged_files = build_files(files: files)

				FileTree.write_yaml(File.join(source_path, '_config.yml'), merged_config)
				FileTree.write(source_path, merged_files)

				site = process_site(merged_config: merged_config, source_path: source_path, destination_path: destination_path)
				yield site, Files.new(source_dir: source_path, dir: destination_path)
			end
		end

		# Merges hashes and blueprints while always returning a deep-cloned result.
		def self.jekyll_merge(base, new_value)
			case base
			when Hash
				DataTools.deep_merge_hashes(base, new_value)
			when JekyllBlueprint
				unless new_value.is_a?(JekyllBlueprint)
					raise ArgumentError, 'jekyll_merge blueprint inputs must both be JekyllBlueprint values.'
				end

				JekyllBlueprint.new(
					config: DataTools.deep_merge_hashes(base.config, new_value.config),
					files: DataTools.deep_merge_hashes(base.files, new_value.files)
				)
			else
				raise ArgumentError, "jekyll_merge does not support base value type #{base.class}."
			end
		end

		private

		# Builds the final Jekyll configuration written to _config.yml.
		def self.build_config(source_path:, destination_path:, config:)
			user_config = coerce_hash(config, field_name: 'config')
			sanitised_user_config = sanitise_config_paths(user_config)
			jekyll_merge(Configuration.default_config(source: source_path, destination: destination_path), sanitised_user_config)
		end

		# Builds the final source file tree written into the temporary site source.
		def self.build_files(files:)
			coerce_hash(files, field_name: 'files')
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
				config_snapshot: DataTools.deep_clone(merged_config)
			), cause: raised_error
		end

		# Validates optional hash inputs and normalises nil to an empty hash.
		def self.coerce_hash(value, field_name:)
			return {} if value.nil?
			return DataTools.deep_clone(value) if value.is_a?(Hash)

			raise ArgumentError, "#{field_name} must be a Hash."
		end

		# Removes forbidden source/destination overrides and warns the caller when supplied.
		def self.sanitise_config_paths(config_hash)
			sanitised_config = DataTools.deep_clone(config_hash)
			warn_forbidden_config_key!(sanitised_config, 'source')
			warn_forbidden_config_key!(sanitised_config, 'destination')
			sanitised_config
		end

		# Deletes a forbidden config key and emits a warning with the attempted value.
		def self.warn_forbidden_config_key!(config_hash, key)
			return unless config_hash.key?(key)

			attempted_value = config_hash.delete(key)
			warn("JekyllTestHarness: ignoring config['#{key}'] (#{attempted_value.inspect}). The harness-managed temporary #{key} always wins.")
		end

		# Infers a stable directory label for the current test example when possible.
		def self.infer_build_label(context)
			rspec_label = infer_rspec_label
			return rspec_label unless rspec_label.nil? || rspec_label.empty?

			minitest_label = infer_minitest_label(context)
			return minitest_label unless minitest_label.nil? || minitest_label.empty?

			Configuration.temporary_directory_prefix
		end

		# Uses RSpec current example metadata for label inference.
		def self.infer_rspec_label
			return nil unless defined?(::RSpec) && ::RSpec.respond_to?(:current_example)

			current_example = ::RSpec.current_example
			return nil if current_example.nil?

			example_file_path = current_example.file_path.to_s
			relative_file_path = example_file_path.gsub(/\A\.\//, '').sub(/\.rb\z/, '')
			example_identifier = current_example.id.to_s.gsub(/\A\.\//, '')
			example_suffix = example_identifier.sub(/\A#{Regexp.escape(example_file_path.gsub(/\A\.\//, ''))}/, '')
			example_suffix = example_identifier if example_suffix.nil? || example_suffix.empty?
			relative_file_path.empty? ? example_suffix : File.join(relative_file_path, example_suffix)
		end
		private_class_method :infer_rspec_label

		# Uses Minitest class and test method names for label inference.
		def self.infer_minitest_label(context)
			return nil if context.nil? || !context.respond_to?(:name)

			test_method_name = context.name.to_s
			test_class_name = context.class.name.to_s
			return nil if test_method_name.empty? || test_class_name.empty?

			File.join(test_class_name, test_method_name)
		end
		private_class_method :infer_minitest_label

		private_class_method :build_config, :build_files, :process_site, :coerce_hash, :sanitise_config_paths, :warn_forbidden_config_key!, :infer_build_label
	end
end
