# frozen_string_literal: true

require 'yaml'

module JekyllTestHarness
	# Builds nested Jekyll source file hashes via a small folder/file DSL.
	class FilesDsl
		# Initialises the builder with a host context for delegated helper calls.
		def initialize(host_context:, project_root:)
			@host_context = host_context
			@project_root = project_root
		end

		# Evaluates the DSL block and returns the resulting nested file hash.
		def build(&block)
			tree = {}
			return tree if block.nil?

			TreeContext.new(tree: tree, host_context: @host_context, project_root: @project_root).evaluate(&block)
		end

		# Supports nested folder/file declarations while delegating unknown methods to the test context.
		class TreeContext
			# Initialises a tree context for one folder level.
			def initialize(tree:, host_context:, project_root:)
				@tree = tree
				@host_context = host_context
				@project_root = project_root
			end

			# Creates a nested folder. The block can define additional folders or files.
			def folder(name, &block)
				folder_tree = {}
				@tree[normalise_entry_name(name, entry_type: 'folder')] = folder_tree
				return folder_tree if block.nil?

				self.class.new(tree: folder_tree, host_context: @host_context, project_root: @project_root).evaluate(&block)
			end

			# Creates a file where the block defines its final string contents.
			def file(name, &block)
				@tree[normalise_entry_name(name, entry_type: 'file')] = FileContext.new(host_context: @host_context, project_root: @project_root).evaluate(&block)
			end

			# Evaluates folder/file calls for this level.
			def evaluate(&block)
				instance_exec(&block)
				@tree
			end

			private

			# Delegates unknown DSL calls to the test context so helper composition still works.
			def method_missing(method_name, *arguments, &block)
				return @host_context.public_send(method_name, *arguments, &block) if @host_context && @host_context.respond_to?(method_name)

				raise NoMethodError, "Unknown helper `#{method_name}` in jekyll_files tree context. Available DSL methods: `folder` and `file`."
			end

			# Mirrors delegated method support checks for introspection.
			def respond_to_missing?(method_name, include_private = false)
				(@host_context && @host_context.respond_to?(method_name, include_private)) || super
			end

			# Normalises file/folder names and rejects empty values that are hard to debug.
			def normalise_entry_name(name, entry_type:)
				entry_name = name.to_s
				raise ArgumentError, "#{entry_type} name must not be empty." if entry_name.strip.empty?

				entry_name
			end
		end

		# Evaluates one file body, supporting either helper composition or direct return values.
		class FileContext
			# Initialises file content collection state.
			def initialize(host_context:, project_root:)
				@host_context = host_context
				@project_root = project_root
				@fragments = []
				@used_content_helpers = false
			end

			# Emits YAML front matter wrapped with separators and a trailing blank line.
			def frontmatter(hash = nil, file: nil, **keyword_hash)
				@used_content_helpers = true
				fixture_hash = file.nil? ? {} : FixtureLoader.read_yaml_hash(file: file, project_root: @project_root)
				inline_hash = coerce_hash(hash, argument_name: 'frontmatter hash')
				inline_hash = DataTools.deep_merge_hashes(inline_hash, coerce_hash(keyword_hash, argument_name: 'frontmatter hash')) unless keyword_hash.empty?
				merged_hash = DataTools.deep_merge_hashes(fixture_hash, inline_hash)

				yaml_payload = YAML.dump(merged_hash).sub(/\A---[ \t]*\n?/, '')
				fragment = "---\n#{yaml_payload}---\n\n"
				@fragments << fragment
				fragment
			end

			# Emits raw file contents directly from inline text and/or a fixture file.
			def contents(text = nil, file: nil)
				@used_content_helpers = true
				fixture_text = file.nil? ? '' : FixtureLoader.read_text(file: file, project_root: @project_root)
				inline_text = text.nil? ? '' : text.to_s
				fragment = "#{fixture_text}#{inline_text}"
				@fragments << fragment
				fragment
			end

			# Evaluates the file block and returns a final string payload.
			def evaluate(&block)
				return '' if block.nil?

				returned_value = instance_exec(&block)
				return @fragments.join if @used_content_helpers

				coerce_return_value(returned_value)
			end

			private

			# Converts nil/hash/string/array file return values into final file text.
			def coerce_return_value(returned_value)
				case returned_value
				when nil
					''
				when String
					returned_value
				when Array
					returned_value.map(&:to_s).join("\n")
				when Hash
					YAML.dump(returned_value)
				else
					raise ArgumentError, "File DSL block must return `String`, `Array`, `Hash`, or `nil` when not using `frontmatter`/`contents`. Received #{ValidationMessages.describe_value(returned_value)}."
				end
			end

			# Normalises optional hash arguments into strict hash values.
			def coerce_hash(value, argument_name:)
				return {} if value.nil?
				return value if value.is_a?(Hash)

				raise ArgumentError, ValidationMessages.type_error(argument_name: argument_name, expected: 'a Hash', value: value, usage: "Pass `#{argument_name}` as a hash, for example: `#{argument_name}(title: 'My page')`.")
			end

			# Delegates unknown helper calls to the outer test context.
			def method_missing(method_name, *arguments, &block)
				return @host_context.public_send(method_name, *arguments, &block) if @host_context && @host_context.respond_to?(method_name)

				raise NoMethodError, "Unknown helper `#{method_name}` in jekyll_files file context. Available DSL methods: `frontmatter` and `contents`."
			end

			# Mirrors delegated method checks for introspection.
			def respond_to_missing?(method_name, include_private = false)
				(@host_context && @host_context.respond_to?(method_name, include_private)) || super
			end
		end
	end
end
