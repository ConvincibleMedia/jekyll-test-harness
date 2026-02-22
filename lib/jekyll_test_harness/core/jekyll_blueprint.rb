# frozen_string_literal: true

module JekyllTestHarness
	# Represents reusable Jekyll build inputs that can be merged and composed in tests.
	class JekyllBlueprint
		attr_reader :config, :files

		# Stores deep-cloned config and file hashes so blueprint instances stay immutable to callers.
		def initialize(config: {}, files: {})
			validate_hash!(config, 'config')
			validate_hash!(files, 'files')

			@config = DataTools.deep_clone(config)
			@files = DataTools.deep_clone(files)
		end

		private

		# Ensures public blueprint inputs are always hash-like structures.
		def validate_hash!(value, field_name)
			return if value.is_a?(Hash)

			raise ArgumentError, "JekyllBlueprint #{field_name} must be a Hash."
		end
	end
end
