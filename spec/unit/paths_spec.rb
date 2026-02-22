# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::Paths do
	it 'builds source and output paths and reads files from each root' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
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

	it 'allows normalised relative paths that remain within the root' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(File.join(source, 'docs'))
			FileUtils.mkdir_p(File.join(destination, 'docs'))
			File.write(File.join(source, 'docs', 'index.md'), 'source')
			File.write(File.join(destination, 'docs', 'index.html'), 'output')
			paths = described_class.new(source: source, destination: destination)

			expect(paths.source_path(File.join('.', 'docs', '.', 'index.md'))).to eq(File.join(source, 'docs', 'index.md'))
			expect(paths.output_path(File.join('docs', '.', 'index.html'))).to eq(File.join(destination, 'docs', 'index.html'))
		end
	end

	it 'rejects paths that escape the source or destination root' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(source)
			FileUtils.mkdir_p(destination)
			paths = described_class.new(source: source, destination: destination)

			expect { paths.source_path('../outside.txt') }.to raise_error(ArgumentError)
			expect { paths.output_path('../outside.html') }.to raise_error(ArgumentError)
		end
	end

	it 'rejects absolute unix and windows-style paths' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			paths = described_class.new(source: File.join(temporary_directory, 'site'), destination: File.join(temporary_directory, '_site'))

			expect { paths.source_path('/etc/passwd') }.to raise_error(ArgumentError)
			expect { paths.output_path('C:/Windows/system.ini') }.to raise_error(ArgumentError)
		end
	end
end

