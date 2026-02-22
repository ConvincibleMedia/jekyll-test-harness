# frozen_string_literal: true

require 'yaml'

module JekyllTestHarness
	# Loads fixture files relative to the configured project root for DSL helper APIs.
	module FixtureLoader
		module_function

		# Reads a fixture file as raw text.
		def read_text(file:, project_root:)
			File.read(resolve_path(file: file, project_root: project_root))
		end

		# Reads and parses a YAML fixture, requiring the root document to be a hash.
		def read_yaml_hash(file:, project_root:)
			loaded_yaml = YAML.safe_load(read_text(file: file, project_root: project_root))
			return {} if loaded_yaml.nil?
			return loaded_yaml if loaded_yaml.is_a?(Hash)

			raise ArgumentError, "Fixture '#{file}' must contain a YAML hash."
		end

		# Resolves a fixture path relative to the project root and blocks path traversal.
		def resolve_path(file:, project_root:)
			project_root_path = File.expand_path(project_root.to_s)
			resolved_path = File.expand_path(file.to_s, project_root_path)
			return resolved_path if path_within_root?(resolved_path, project_root_path)

			raise ArgumentError, "Fixture path escapes the configured project root: #{file}"
		end

		# Returns true when the candidate path is inside the configured project root.
		def path_within_root?(candidate_path, root_path)
			normalised_candidate = File.expand_path(candidate_path).tr('\\', '/').downcase
			normalised_root = File.expand_path(root_path).tr('\\', '/').downcase
			normalised_candidate == normalised_root || normalised_candidate.start_with?("#{normalised_root}/")
		end
		private_class_method :path_within_root?
	end
end
