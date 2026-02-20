# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Consumer simulation', :consumer_simulation do
	# Runs Bundler via the current Ruby to avoid shell execute issues on Windows.
	def bundler_command(*arguments)
		[RbConfig.ruby, '-S', 'bundle', "_#{Bundler::VERSION}_", *arguments]
	end

	# Runs a command in a project directory and returns stdout, stderr, and status.
	def run_command(*command, chdir:)
		stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
		{ stdout: stdout, stderr: stderr, status: status }
	end

	# Writes a file while ensuring its parent directory exists.
	def write_file(path, content)
		FileUtils.mkdir_p(File.dirname(path))
		File.write(path, content)
	end

	# Creates a minimal plugin project that consumes this gem as a dev dependency.
	def create_consumer_project(project_root:, include_failing_spec:)
		gem_root = File.expand_path('../..', __dir__).tr('\\', '/')

		write_file(
			File.join(project_root, 'Gemfile'),
			<<~RUBY
				source "https://rubygems.org"

				gem "jekyll", ">= 3.8", "< 5.0"
				gem "rspec", "~> 3.13"
				gem "jekyll-test-harness", path: "#{gem_root}"
			RUBY
		)

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

		write_file(
			File.join(project_root, 'spec', 'spec_helper.rb'),
			<<~RUBY
				# frozen_string_literal: true

				require 'bundler/setup'
				require 'rspec'
				require 'jekyll_test_harness/rspec'
				require_relative '../lib/consumer_fixture_plugin'

				RSpec.configure do |config|
					Jekyll::TestHarness::RSpec.configure(config)
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

	it 'passes when a consumer plugin project runs bundle exec rspec' do
		Dir.mktmpdir('jth-consumer-pass-') do |project_root|
			create_consumer_project(project_root: project_root, include_failing_spec: false)

			install_result = run_command(*bundler_command('install'), chdir: project_root)
			expect(install_result[:status].success?).to be(true), "bundle install failed:\n#{install_result[:stdout]}\n#{install_result[:stderr]}"

			rspec_result = run_command(*bundler_command('exec', 'rspec'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(true), "bundle exec rspec failed:\n#{rspec_result[:stdout]}\n#{rspec_result[:stderr]}"
			expect(rspec_result[:stdout]).to include('1 example, 0 failures')
		end
	end

	it 'produces readable failure output for consumer specs' do
		Dir.mktmpdir('jth-consumer-fail-') do |project_root|
			create_consumer_project(project_root: project_root, include_failing_spec: true)

			install_result = run_command(*bundler_command('install'), chdir: project_root)
			expect(install_result[:status].success?).to be(true), "bundle install failed:\n#{install_result[:stdout]}\n#{install_result[:stderr]}"

			rspec_result = run_command(*bundler_command('exec', 'rspec'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(false)
			expect(rspec_result[:stdout]).to include('build_jekyll_site')
			expect(rspec_result[:stdout]).to include('SiteHarness.with_site requires a block.')
		end
	end
end
