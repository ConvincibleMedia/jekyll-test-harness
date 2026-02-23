# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Consumer simulation', :consumer_simulation do
	include ConsumerSimulationHelpers

	it 'passes when a consumer plugin project runs RSpec' do
		Dir.mktmpdir('jth-consumer-pass-') do |project_root|
			create_rspec_consumer_project(project_root: project_root, include_failing_spec: false)

			rspec_result = run_command(*ruby_command('rspec', 'spec/integration_spec.rb'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(true), "RSpec run failed:\n#{rspec_result[:stdout]}\n#{rspec_result[:stderr]}"
			expect(rspec_result[:stdout]).to include('1 example, 0 failures')
		end
	end

	it 'produces readable failure output for consumer specs' do
		Dir.mktmpdir('jth-consumer-fail-') do |project_root|
			create_rspec_consumer_project(project_root: project_root, include_failing_spec: true)

			rspec_result = run_command(*ruby_command('rspec', 'spec/integration_spec.rb'), chdir: project_root)
			expect(rspec_result[:status].success?).to be(false)
			expect(rspec_result[:stdout]).to include('jekyll_build')
			expect(rspec_result[:stdout]).to include('SiteHarness.with_site requires a block.')
		end
	end
end
