# frozen_string_literal: true

require_relative 'site_harness'

module Jekyll
	module TestHarness
		# Adds convenience helpers for Minitest without hiding SiteHarness behaviour.
		module Minitest
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

			# Wires harness helpers into a Minitest test case class.
			def configure(test_case_class = default_test_case_class)
				unless test_case_class.respond_to?(:include)
					raise ArgumentError, 'Minitest test case class must respond to #include.'
				end

				test_case_class.include(Helpers)
				test_case_class
			end

			# Looks up the default Minitest test case class and raises a clear usage error if missing.
			def default_test_case_class
				return ::Minitest::Test if defined?(::Minitest::Test)

				raise NameError, "Minitest::Test is not defined. Require 'minitest/autorun' or pass a test case class to configure."
			end
			private_class_method :default_test_case_class
		end
	end
end
