# frozen_string_literal: true

require 'tmpdir'

module JekyllSpecSupport
	# Creates and cleans up temporary directories for Jekyll specs.
	module TemporaryDirectory
		# Yields a temporary directory path and ensures it is removed afterwards.
		def self.with_dir(prefix: 'jekyll-spec-')
			Dir.mktmpdir(prefix) { |dir| yield dir }
		end
	end
end
