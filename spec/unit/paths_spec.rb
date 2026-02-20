# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Jekyll::TestHarness::Paths do
	it 'builds source and output paths and reads files from each root' do
		Jekyll::TestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(source)
			FileUtils.mkdir_p(destination)
			File.write(File.join(source, 'index.md'), 'Source content')
			FileUtils.mkdir_p(File.join(destination, 'docs'))
			File.write(File.join(destination, 'docs', 'index.html'), '<p>Output content</p>')

			paths = described_class.new(source: source, destination: destination)

			expect(paths.source_path('index.md')).to eq(File.join(source, 'index.md'))
			expect(paths.output_path('docs/index.html')).to eq(File.join(destination, 'docs', 'index.html'))
			expect(paths.read_source('index.md')).to eq('Source content')
			expect(paths.read_output('docs/index.html')).to eq('<p>Output content</p>')
		end
	end

	it 'rejects paths that escape the source or destination root' do
		Jekyll::TestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(source)
			FileUtils.mkdir_p(destination)
			paths = described_class.new(source: source, destination: destination)

			expect { paths.source_path('../outside.txt') }.to raise_error(ArgumentError)
			expect { paths.output_path('../outside.html') }.to raise_error(ArgumentError)
		end
	end
end
