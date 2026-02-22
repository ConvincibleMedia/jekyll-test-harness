# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module JekyllTestHarness
	# Manages temporary build directories with deterministic naming and cleanup behaviour.
	module TemporaryDirectory
		@directory_counter = 0
		@counter_mutex = Mutex.new

		module_function

		# Yields a temporary directory and removes it afterwards unless retention is requested.
		def with_dir(prefix: Configuration.temporary_directory_prefix, root_directory: nil, label: nil, keep_on_error: false)
			raise MissingBlockError, 'TemporaryDirectory.with_dir requires a block.' unless block_given?

			root_directory_path = root_directory.nil? ? Dir.tmpdir : File.expand_path(root_directory.to_s)
			temporary_directory_path = create_directory(root_directory: root_directory_path, prefix: prefix, label: label)
			yield temporary_directory_path
		ensure
			directory_exists = !temporary_directory_path.nil? && File.exist?(temporary_directory_path)
			keep_failed_directory = keep_on_error && !$ERROR_INFO.nil?
			cleanup_directory(
				temporary_directory_path: temporary_directory_path,
				directory_exists: directory_exists,
				keep_failed_directory: keep_failed_directory
			)
		end

		# Creates a uniquely named directory below the selected root.
		def create_directory(root_directory:, prefix:, label:)
			normalised_segments = normalise_label_segments(label, prefix: prefix)
			FileUtils.mkdir_p(File.join(root_directory, *normalised_segments[0...-1])) unless normalised_segments.length < 2

			loop do
				candidate_basename = "#{normalised_segments.last}-#{next_directory_counter}"
				candidate_path = File.join(root_directory, *normalised_segments[0...-1], candidate_basename)
				next if File.exist?(candidate_path)

				FileUtils.mkdir_p(candidate_path)
				return candidate_path
			end
		end
		private_class_method :create_directory

		# Removes build directories unless retention is requested.
		def cleanup_directory(temporary_directory_path:, directory_exists:, keep_failed_directory:)
			return if !directory_exists || keep_failed_directory

			FileUtils.remove_entry(temporary_directory_path)
		end
		private_class_method :cleanup_directory

		# Converts a label into safe path segments while preserving hierarchy when supplied.
		def normalise_label_segments(label, prefix:)
			raw_segments = label.to_s.tr('\\', '/').split('/').map(&:strip).reject(&:empty?)
			safe_segments = raw_segments.map { |segment| normalise_segment(segment) }.reject(&:empty?)
			safe_segments = [normalise_segment(prefix)] if safe_segments.empty?
			safe_segments
		end
		private_class_method :normalise_label_segments

		# Converts one segment to filesystem-safe lowercase kebab-case.
		def normalise_segment(segment)
			segment.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '').gsub(/-+/, '-')
		end
		private_class_method :normalise_segment

		# Returns a thread-safe, process-local directory counter.
		def next_directory_counter
			@counter_mutex.synchronize do
				@directory_counter += 1
			end
		end
		private_class_method :next_directory_counter

	end
end
