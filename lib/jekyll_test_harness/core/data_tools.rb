# frozen_string_literal: true

module JekyllTestHarness
	# Provides deep clone and deep merge helpers used across config, files, and blueprints.
	module DataTools
		module_function

		# Returns a deep clone so callers can safely mutate returned values.
		def deep_clone(value)
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

		# Deep-merges hashes in the same spirit as ActiveSupport::Hash#deep_merge.
		def deep_merge_hashes(base_hash, new_hash)
			unless base_hash.is_a?(Hash) && new_hash.is_a?(Hash)
				raise ArgumentError, 'jekyll_merge hash inputs must both be Hash values.'
			end

			merged_hash = deep_clone(base_hash)
			new_hash.each do |key, value|
				merged_hash[key] = if merged_hash[key].is_a?(Hash) && value.is_a?(Hash)
					deep_merge_hashes(merged_hash[key], value)
				else
					deep_clone(value)
				end
			end
			merged_hash
		end
	end
end
