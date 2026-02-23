# frozen_string_literal: true

require 'yaml'

module JekyllTestHarness
	# Loads fixture files relative to the configured project root for DSL helper APIs.
	module FixtureLoader
		module_function

		# Reads a fixture file as raw text.
		def read_text(file:, project_root:)
			resolved_path = resolve_path(file: file, project_root: project_root)
			File.read(resolved_path)
		rescue Errno::ENOENT
			raise ArgumentError, "Fixture file was not found: #{file.inspect}. Resolved path: #{resolved_path}. Project root: #{File.expand_path(project_root.to_s)}."
		end

		# Reads and parses a YAML fixture, requiring the root document to be a hash.
		def read_yaml_hash(file:, project_root:)
			loaded_yaml = YAML.safe_load(read_text(file: file, project_root: project_root))
			return {} if loaded_yaml.nil?
			return loaded_yaml if loaded_yaml.is_a?(Hash)

			raise ArgumentError, "Fixture '#{file}' must contain a YAML hash. Received #{ValidationMessages.describe_value(loaded_yaml)}."
		rescue Psych::SyntaxError => raised_error
			raise ArgumentError, "Fixture '#{file}' contains invalid YAML: #{raised_error.problem || raised_error.message}."
		end

		# Resolves a fixture path relative to the project root and blocks path traversal.
		def resolve_path(file:, project_root:)
			fixture_path = normalise_fixture_path(file)
			project_root_path = normalise_project_root(project_root)
			resolved_path = File.expand_path(fixture_path, project_root_path)
			return resolved_path if path_within_root?(resolved_path, project_root_path)

			raise ArgumentError, "Fixture path escapes the configured project root: #{fixture_path.inspect}. Project root: #{project_root_path}."
		end

		# Returns true when the candidate path is inside the configured project root.
		def path_within_root?(candidate_path, root_path)
			normalised_candidate = File.expand_path(candidate_path).tr('\\', '/').downcase
			normalised_root = File.expand_path(root_path).tr('\\', '/').downcase
			normalised_candidate == normalised_root || normalised_candidate.start_with?("#{normalised_root}/")
		end
		private_class_method :path_within_root?

		# Normalises and validates fixture path arguments.
		def normalise_fixture_path(file)
			fixture_path = if file.is_a?(String)
				file
			elsif file.respond_to?(:to_path)
				file.to_path.to_s
			else
				raise ArgumentError, ValidationMessages.type_error(
					argument_name: 'file',
					expected: 'a String path or Pathname',
					value: file,
					usage: "Use a project-relative fixture path such as `file: 'spec/fixtures/dsl/config.yml'`."
				)
			end

			raise ArgumentError, "file must not be empty. Use a project-relative fixture path such as `file: 'spec/fixtures/dsl/config.yml'`." if fixture_path.strip.empty?

			fixture_path
		end
		private_class_method :normalise_fixture_path

		# Normalises and validates project root arguments.
		def normalise_project_root(project_root)
			root_path = if project_root.is_a?(String)
				project_root
			elsif project_root.respond_to?(:to_path)
				project_root.to_path.to_s
			else
				raise ArgumentError, ValidationMessages.type_error(
					argument_name: 'project_root',
					expected: 'a String path or Pathname',
					value: project_root,
					usage: 'Pass the project root captured by `JekyllTestHarness.install!`.'
				)
			end
			raise ArgumentError, 'project_root must not be empty.' if root_path.strip.empty?

			File.expand_path(root_path)
		end
		private_class_method :normalise_project_root
	end
end
