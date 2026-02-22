# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Consumer simulation', :consumer_simulation do
	include ConsumerSimulationHelpers

	it 'passes when a consumer plugin project runs bundle exec rspec' do
		Dir.mktmpdir('jth-consumer-pass-') do |project_root|
			create_rspec_consumer_project(project_root: project_root, include_failing_spec: false)

			install_result = run_command(*bundler_command('install'), chdir: project_root)
			expect(install_result[:status].success?).to be(true), "bundle install failed:\n#{install_result[:stdout]}\n#{install_result[:stderr]}"

			rspec_result = run_command(*bundler_command('exec', 'rspec'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(true), "bundle exec rspec failed:\n#{rspec_result[:stdout]}\n#{rspec_result[:stderr]}"
			expect(rspec_result[:stdout]).to include('1 example, 0 failures')
		end
	end

	it 'produces readable failure output for consumer specs' do
		Dir.mktmpdir('jth-consumer-fail-') do |project_root|
			create_rspec_consumer_project(project_root: project_root, include_failing_spec: true)

			install_result = run_command(*bundler_command('install'), chdir: project_root)
			expect(install_result[:status].success?).to be(true), "bundle install failed:\n#{install_result[:stdout]}\n#{install_result[:stderr]}"

			rspec_result = run_command(*bundler_command('exec', 'rspec'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(false)
			expect(rspec_result[:stdout]).to include('jekyll_build')
			expect(rspec_result[:stdout]).to include('SiteHarness.with_site requires a block.')
		end
	end
end
