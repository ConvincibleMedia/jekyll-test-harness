# frozen_string_literal: true

module JekyllTestHarness
	# Provides framework-agnostic helper methods for test examples.
	module Helpers
		# Builds a temporary site using the core SiteHarness API.
		def build_jekyll_site(config: {}, files: {}, base_config: {}, base_files: {}, default_scaffold: true, keep_site_on_failure: false, &block)
			JekyllTestHarness::SiteHarness.with_site(
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
			JekyllTestHarness::SiteHarness.merge_data(base, overrides)
		end
	end
end
