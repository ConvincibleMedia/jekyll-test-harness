# frozen_string_literal: true

module JekyllTestHarness
	SUPPORTED_INSTALL_FRAMEWORKS = %i[auto rspec minitest].freeze

	module_function

	# Installs harness helpers into RSpec or Minitest based on explicit or automatic framework selection.
	def install!(framework: :auto, minitest_test_case: nil, failures: Configuration::DEFAULT_FAILURE_MODE, output: nil)
		Configuration.configure_runtime!(failures: failures, output: output, project_root: Dir.pwd)
		selected_framework = resolve_framework(framework)
		case selected_framework
		when :rspec
			rspec_configuration = default_rspec_configuration
			rspec_configuration.include(Helpers)
			rspec_configuration
		when :minitest
			target_minitest_test_case = minitest_test_case || default_minitest_test_case
			validate_include_target!(target_minitest_test_case, 'Minitest test case class')
			target_minitest_test_case.include(Helpers)
			target_minitest_test_case
		else
			raise ArgumentError, "Unsupported framework '#{selected_framework}'. Supported frameworks: #{SUPPORTED_INSTALL_FRAMEWORKS.map(&:inspect).join(', ')}."
		end
	end

	# Supports the previous method name while routing callers to the unified install API.
	def configure(*arguments, **options)
		framework = options.key?(:framework) ? options[:framework] : arguments.first
		install!(framework: framework || :auto, **options.reject { |key, _value| key == :framework })
	end

	# Returns the currently available test frameworks in the running process.
	def available_frameworks
		detected_frameworks = []
		detected_frameworks << :rspec if rspec_available?
		detected_frameworks << :minitest if minitest_available?
		detected_frameworks
	end

	# Resolves explicit and automatic framework selection.
	def resolve_framework(framework)
		normalised_framework = framework.to_sym
		unless SUPPORTED_INSTALL_FRAMEWORKS.include?(normalised_framework)
			raise ArgumentError, "Unsupported framework '#{framework}'. Supported frameworks: #{SUPPORTED_INSTALL_FRAMEWORKS.map(&:inspect).join(', ')}."
		end

		return resolve_automatic_framework if normalised_framework == :auto

		normalised_framework
	end
	private_class_method :resolve_framework

	# Selects a single framework from loaded frameworks or raises clear guidance.
	def resolve_automatic_framework
		detected_frameworks = available_frameworks
		case detected_frameworks.length
		when 1
			detected_frameworks.first
		when 0
			raise NameError, "No supported test framework is loaded. Require 'rspec' or 'minitest/autorun' before calling JekyllTestHarness.install!, or pass framework: explicitly."
		else
			raise ArgumentError, "Multiple supported frameworks are loaded (#{detected_frameworks.join(', ')}). Call JekyllTestHarness.install!(framework: :rspec) or JekyllTestHarness.install!(framework: :minitest) explicitly."
		end
	end
	private_class_method :resolve_automatic_framework

	# Returns true when the requested framework is currently loaded.
	def framework_available?(framework)
		case framework
		when :rspec
			rspec_available?
		when :minitest
			minitest_available?
		else
			false
		end
	end
	private_class_method :framework_available?

	# Detects whether RSpec configuration is available for helper inclusion.
	def rspec_available?
		defined?(::RSpec) && ::RSpec.respond_to?(:configuration)
	end
	private_class_method :rspec_available?

	# Detects whether Minitest test case support is available for helper inclusion.
	def minitest_available?
		defined?(::Minitest::Test)
	end
	private_class_method :minitest_available?

	# Returns a default RSpec configuration target when RSpec is loaded.
	def default_rspec_configuration
		return ::RSpec.configuration if rspec_available?

		raise framework_not_loaded_error(:rspec)
	end
	private_class_method :default_rspec_configuration

	# Returns a default Minitest test case class when Minitest is loaded.
	def default_minitest_test_case
		return ::Minitest::Test if minitest_available?

		raise framework_not_loaded_error(:minitest)
	end
	private_class_method :default_minitest_test_case

	# Raises consistent framework-specific guidance when an explicit framework is unavailable.
	def framework_not_loaded_error(framework)
		case framework
		when :rspec
			NameError.new("RSpec is not available. Require 'rspec' before calling JekyllTestHarness.install!(framework: :rspec).")
		when :minitest
			NameError.new("Minitest::Test is not available. Require 'minitest/autorun' before calling JekyllTestHarness.install!(framework: :minitest).")
		else
			NameError.new("Framework '#{framework}' is not available.")
		end
	end
	private_class_method :framework_not_loaded_error

	# Validates that framework include targets can accept helper module inclusion.
	def validate_include_target!(target, target_description)
		return if target.respond_to?(:include)

		raise ArgumentError, "#{target_description} must respond to #include."
	end
	private_class_method :validate_include_target!
end
