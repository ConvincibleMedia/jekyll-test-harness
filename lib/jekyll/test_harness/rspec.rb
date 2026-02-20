# frozen_string_literal: true

require_relative 'site_harness'

module Jekyll
	module TestHarness
		# Adds convenience helpers to RSpec without hiding SiteHarness behaviour.
		module RSpec
			# Exposes helper methods that delegate to the core harness API.
			module Helpers
				# Builds a temporary site using the core SiteHarness API.
				def build_jekyll_site(config: {}, files: {}, base_config: {}, base_files: {}, default_scaffold: true, keep_site_on_failure: false, &block)
					Jekyll::TestHarness::SiteHarness.with_site(
						config: config,
						files: files,
						base_config: base_config,
						base_files: base_files,
						default_scaffold: default_scaffold,
						keep_site_on_failure: keep_site_on_failure,
						&block
					)
				end

				# Deep-merges hash-like data for shared config and fixture composition.
				def merge_jekyll_data(base, overrides)
					Jekyll::TestHarness::SiteHarness.merge_data(base, overrides)
				end
			end

			module_function

			# Wires harness helpers into an RSpec configuration instance.
			def configure(configuration)
				configuration.include(Helpers)
			end
		end
	end
end
