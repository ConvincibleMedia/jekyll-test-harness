# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Minitest consumer simulation', :consumer_simulation do
	include ConsumerSimulationHelpers

	it 'passes when a consumer plugin project runs a Minitest test file' do
		Dir.mktmpdir('jth-consumer-minitest-pass-') do |project_root|
			create_minitest_consumer_project(project_root: project_root, include_failing_test: false)

			minitest_result = run_command(RbConfig.ruby, '-Itest', 'test/integration_test.rb', chdir: project_root)
			expect(minitest_result[:status].success?).to be(true), "Minitest run failed:\n#{minitest_result[:stdout]}\n#{minitest_result[:stderr]}"
			expect(minitest_result[:stdout]).to match(/1 runs?, \d+ assertions?, 0 failures, 0 errors, 0 skips/)
		end
	end

	it 'produces readable failure output for consumer Minitest failures' do
		Dir.mktmpdir('jth-consumer-minitest-fail-') do |project_root|
			create_minitest_consumer_project(project_root: project_root, include_failing_test: true)

			minitest_result = run_command(RbConfig.ruby, '-Itest', 'test/integration_test.rb', chdir: project_root)
			expect(minitest_result[:status].success?).to be(false)
			expect(minitest_result[:stdout]).to include('jekyll_build')
			expect(minitest_result[:stdout]).to include('SiteHarness.with_site requires a block.')
		end
	end
end
