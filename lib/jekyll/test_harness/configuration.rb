# frozen_string_literal: true

module Jekyll
	module TestHarness
		# Provides shared defaults used by SiteHarness.
		module Configuration
			TEMPORARY_DIRECTORY_PREFIX = 'jekyll-test-harness-'

			DEFAULT_SCAFFOLD_FILES = {
				'_layouts' => {
					'default.html' => <<~HTML
						<!doctype html>
						<html>
							<head>
								<meta charset="utf-8">
								<title>Jekyll Test Harness</title>
							</head>
							<body>
								{{ content }}
							</body>
						</html>
					HTML
				},
				'index.md' => <<~MARKDOWN
					---
					layout: default
					---
					Hello from the Jekyll test harness default scaffold.
				MARKDOWN
			}.freeze

			module_function

			# Returns the baseline Jekyll configuration for a temporary site.
			def default_config(source:, destination:)
				{
					'source' => source,
					'destination' => destination,
					'quiet' => true,
					'incremental' => false
				}
			end

			# Returns a deep copy of scaffold files so callers can safely mutate results.
			def default_scaffold_files
				deep_clone(DEFAULT_SCAFFOLD_FILES)
			end

			# Exposes the temporary directory prefix so it stays consistent across helpers.
			def temporary_directory_prefix
				TEMPORARY_DIRECTORY_PREFIX
			end

			# Duplicates hash-like data used for configuration and file trees.
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
			private_class_method :deep_clone
		end
	end
end
