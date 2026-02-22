# frozen_string_literal: true

require_relative '../spec_helper'
require 'stringio'

RSpec.describe 'Failure diagnostics' do
	# Silences expected Liquid parse noise from intentionally-invalid fixtures.
	def suppress_expected_build_stderr
		original_stderr = $stderr
		$stderr = StringIO.new
		yield
	ensure
		$stderr = original_stderr
	end

	it 'wraps Jekyll build failures in SiteBuildError with debug context' do
		files = {
			'_layouts' => {
				'default.html' => '{% if %}'
			}
		}

		expect do
			suppress_expected_build_stderr do
				build_jekyll_site(files: files) { |_site, _paths| }
			end
		end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
			expect(error.message).to include('Jekyll site build failed:')
			expect(error.message).to include('keep_site_on_failure: true')
			expect(error.source_path).not_to be_nil
			expect(error.destination_path).not_to be_nil
			expect(error.config_snapshot).to be_a(Hash)
			expect(error.original_error).to be_a(StandardError)
		}
	end

	it 'retains temporary directories on failure when keep_site_on_failure is enabled' do
		files = {
			'_layouts' => {
				'default.html' => '{% if %}'
			}
		}
		temporary_site_root = nil

		expect do
			suppress_expected_build_stderr do
				build_jekyll_site(files: files, keep_site_on_failure: true) { |_site, _paths| }
			end
		end.to raise_error(JekyllTestHarness::SiteBuildError) { |error|
			temporary_site_root = File.dirname(error.source_path)
		}

		expect(Dir.exist?(temporary_site_root)).to be(true)
		FileUtils.remove_entry(temporary_site_root)
	end
end

