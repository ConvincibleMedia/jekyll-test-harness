# frozen_string_literal: true

module JekyllTestHarness
	# Provides framework-agnostic helper methods for test examples.
	module Helpers
		UNSET_ARGUMENT = Object.new

		# Builds and processes one temporary Jekyll site for the current test.
		def jekyll_build(blueprint = nil, config: UNSET_ARGUMENT, files: UNSET_ARGUMENT, &block)
			buffered_config, buffered_files = consume_jekyll_buffers
			selected_blueprint = coerce_blueprint(blueprint)

			selected_config = config.equal?(UNSET_ARGUMENT) ? buffered_config : coerce_hash(config, field_name: 'config')
			selected_files = files.equal?(UNSET_ARGUMENT) ? buffered_files : coerce_hash(files, field_name: 'files')
			merged_config = jekyll_merge(selected_blueprint.config, selected_config)
			merged_files = jekyll_merge(selected_blueprint.files, selected_files)

			JekyllTestHarness::SiteHarness.with_site(config: merged_config, files: merged_files, context: self, &block)
		end

		# Deep-merges hash values or blueprint values using harness merge semantics.
		def jekyll_merge(base, new_value)
			JekyllTestHarness::SiteHarness.jekyll_merge(base, new_value)
		end

		# Creates a reusable blueprint object from config and files hash inputs.
		def jekyll_blueprint(config: {}, files: {})
			JekyllTestHarness::JekyllBlueprint.new(
				config: coerce_hash(config, field_name: 'config'),
				files: coerce_hash(files, field_name: 'files')
			)
		end

		# Merges config into the buffered build config and returns the merged addition.
		def jekyll_config(config = nil, file: nil)
			fixture_config = file.nil? ? {} : JekyllTestHarness::FixtureLoader.read_yaml_hash(file: file, project_root: JekyllTestHarness::Configuration.project_root)
			inline_config = coerce_hash(config, field_name: 'config')
			resolved_config = jekyll_merge(fixture_config, inline_config)
			@jekyll_buffered_config = jekyll_merge(jekyll_buffered_config, resolved_config)
			JekyllTestHarness::DataTools.deep_clone(resolved_config)
		end

		# Builds files with the folder/file DSL, buffers them, and returns the generated hash.
		def jekyll_files(&block)
			resolved_files = JekyllTestHarness::FilesDsl.new(host_context: self, project_root: JekyllTestHarness::Configuration.project_root).build(&block)
			@jekyll_buffered_files = jekyll_merge(jekyll_buffered_files, resolved_files)
			JekyllTestHarness::DataTools.deep_clone(resolved_files)
		end

		private

		# Returns buffered config as a hash.
		def jekyll_buffered_config
			@jekyll_buffered_config ||= {}
		end

		# Returns buffered files as a hash.
		def jekyll_buffered_files
			@jekyll_buffered_files ||= {}
		end

		# Returns the current buffers and flushes them immediately.
		def consume_jekyll_buffers
			buffered_config = JekyllTestHarness::DataTools.deep_clone(jekyll_buffered_config)
			buffered_files = JekyllTestHarness::DataTools.deep_clone(jekyll_buffered_files)
			@jekyll_buffered_config = {}
			@jekyll_buffered_files = {}
			[buffered_config, buffered_files]
		end

		# Normalises nil/hash values and rejects unsupported input types.
		def coerce_hash(value, field_name:)
			return {} if value.nil?
			return JekyllTestHarness::DataTools.deep_clone(value) if value.is_a?(Hash)

			raise ArgumentError, "#{field_name} must be a Hash."
		end

		# Normalises optional blueprint arguments for jekyll_build.
		def coerce_blueprint(value)
			return JekyllTestHarness::JekyllBlueprint.new if value.nil?
			return value if value.is_a?(JekyllTestHarness::JekyllBlueprint)

			raise ArgumentError, 'jekyll_build first argument must be a JekyllBlueprint when provided.'
		end
	end
end
