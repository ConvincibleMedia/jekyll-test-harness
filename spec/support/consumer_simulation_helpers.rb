# frozen_string_literal: true

# Shared helper methods for end-to-end consumer simulation subprocess tests.
module ConsumerSimulationHelpers
	# Runs Bundler via the current Ruby to avoid shell execute issues on Windows.
	def bundler_command(*arguments)
		[RbConfig.ruby, '-S', 'bundle', "_#{Bundler::VERSION}_", *arguments]
	end

	# Runs a command in a project directory and returns stdout, stderr, and status.
	def run_command(*command, chdir:)
		command_environment = Bundler.unbundled_env.merge('BUNDLE_GEMFILE' => File.join(chdir, 'Gemfile'))
		stdout, stderr, status = Open3.capture3(command_environment, *command, chdir: chdir)
		{ stdout: stdout, stderr: stderr, status: status }
	end

	# Writes a file while ensuring its parent directory exists.
	def write_file(path, content)
		FileUtils.mkdir_p(File.dirname(path))
		File.write(path, content)
	end

	# Returns a normalised absolute path to this gem root for temporary consumer Gemfiles.
	def gem_root_path
		File.expand_path('../..', __dir__).tr('\\', '/')
	end

	# Creates a minimal plugin file used by simulated consumer projects.
	def write_consumer_fixture_plugin(project_root:)
		write_file(
			File.join(project_root, 'lib', 'consumer_fixture_plugin.rb'),
			<<~RUBY
				# frozen_string_literal: true

				Jekyll::Hooks.register :documents, :pre_render do |document|
					document.data['consumer_hook_marker'] = 'consumer-hooked'
				end

				module ConsumerFixturePlugin
					class ConsumerTag < Liquid::Tag
						def render(_context)
							'consumer-tag-output'
						end
					end
				end

				Liquid::Template.register_tag('consumer_tag', ConsumerFixturePlugin::ConsumerTag)
			RUBY
		)
	end

	# Writes a Gemfile shared by both simulated consumer frameworks.
	def write_consumer_gemfile(project_root:)
		write_file(
			File.join(project_root, 'Gemfile'),
			<<~RUBY
				source "https://rubygems.org"

				gem "jekyll", ">= 3.8", "< 5.0"
				gem "rspec", "~> 3.13"
				gem "minitest", ">= 5.0"
				gem "jekyll-test-harness", path: "#{gem_root_path}"
			RUBY
		)
	end

	# Creates a minimal RSpec consumer project that uses jekyll-test-harness.
	def create_rspec_consumer_project(project_root:, include_failing_spec:)
		write_consumer_gemfile(project_root: project_root)
		write_consumer_fixture_plugin(project_root: project_root)

		write_file(
			File.join(project_root, 'spec', 'spec_helper.rb'),
			<<~RUBY
				# frozen_string_literal: true

				require 'bundler/setup'
				require 'rspec'
				require 'jekyll_test_harness'
				require_relative '../lib/consumer_fixture_plugin'

				RSpec.configure do |config|
					JekyllTestHarness.install!(:rspec, rspec_configuration: config)
				end
			RUBY
		)

		spec_body = if include_failing_spec
			<<~RUBY
				# frozen_string_literal: true

				require_relative 'spec_helper'

				RSpec.describe 'consumer failure output' do
					it 'shows readable harness failures' do
						build_jekyll_site(default_scaffold: false)
					end
				end
			RUBY
		else
			<<~RUBY
				# frozen_string_literal: true

				require_relative 'spec_helper'

				RSpec.describe 'consumer harness usage' do
					it 'builds a site using the harness DSL' do
						files = {
							'_layouts' => {
								'default.html' => '<html><body>{% consumer_tag %}{{ content }}</body></html>'
							},
							'_posts' => {
								'2026-01-01-consumer.md' => "---\\nlayout: default\\npermalink: /docs/consumer.html\\n---\\nConsumer body\\n"
							}
						}

						build_jekyll_site(files: files) do |site, paths|
							document = site.collections.fetch('posts').docs.first
							expect(document.data['consumer_hook_marker']).to eq('consumer-hooked')
							expect(paths.read_output('docs/consumer.html')).to include('consumer-tag-output')
						end
					end
				end
			RUBY
		end

		write_file(File.join(project_root, 'spec', 'integration_spec.rb'), spec_body)
	end

	# Creates a minimal Minitest consumer project that uses jekyll-test-harness.
	def create_minitest_consumer_project(project_root:, include_failing_test:)
		write_consumer_gemfile(project_root: project_root)
		write_consumer_fixture_plugin(project_root: project_root)

		write_file(
			File.join(project_root, 'test', 'test_helper.rb'),
			<<~RUBY
				# frozen_string_literal: true

				require 'bundler/setup'
				require 'minitest/autorun'
				require 'jekyll_test_harness'
				require_relative '../lib/consumer_fixture_plugin'

				JekyllTestHarness.install!(:minitest)
			RUBY
		)

		test_body = if include_failing_test
			<<~RUBY
				# frozen_string_literal: true

				require_relative 'test_helper'

				class ConsumerFailureOutputTest < Minitest::Test
					def test_shows_readable_harness_failures
						build_jekyll_site(default_scaffold: false)
					end
				end
			RUBY
		else
			<<~RUBY
				# frozen_string_literal: true

				require_relative 'test_helper'

				class ConsumerHarnessUsageTest < Minitest::Test
					def test_builds_a_site_using_the_harness_dsl
						files = {
							'_layouts' => {
								'default.html' => '<html><body>{% consumer_tag %}{{ content }}</body></html>'
							},
							'_posts' => {
								'2026-01-01-consumer.md' => "---\\nlayout: default\\npermalink: /docs/consumer.html\\n---\\nConsumer body\\n"
							}
						}

						build_jekyll_site(files: files) do |site, paths|
							document = site.collections.fetch('posts').docs.first
							assert_equal('consumer-hooked', document.data['consumer_hook_marker'])
							assert_includes(paths.read_output('docs/consumer.html'), 'consumer-tag-output')
						end
					end
				end
			RUBY
		end

		write_file(File.join(project_root, 'test', 'integration_test.rb'), test_body)
	end
end

