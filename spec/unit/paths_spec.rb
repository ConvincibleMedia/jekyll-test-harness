# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe JekyllTestHarness::Files do
	it 'keeps the legacy Paths constant as an alias of Files' do
		expect(JekyllTestHarness::Paths).to equal(JekyllTestHarness::Files)
	end

	it 'builds output and source paths and reads files from each root' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(source)
			FileUtils.mkdir_p(destination)
			File.write(File.join(source, 'index.md'), 'Source content')
			FileUtils.mkdir_p(File.join(destination, 'docs'))
			File.write(File.join(destination, 'docs', 'index.html'), '<p>Output content</p>')

			files = described_class.new(source_dir: source, dir: destination)

			expect(files.dir).to eq(destination)
			expect(files.source_dir).to eq(source)
			expect(files.path('docs/index.html')).to eq(File.join(destination, 'docs', 'index.html'))
			expect(files.source_path('index.md')).to eq(File.join(source, 'index.md'))
			expect(files.read('docs/index.html')).to eq('<p>Output content</p>')
			expect(files.source_read('index.md')).to eq('Source content')
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
			files = described_class.new(source_dir: source, dir: destination)

			expect(files.source_path(File.join('.', 'docs', '.', 'index.md'))).to eq(File.join(source, 'docs', 'index.md'))
			expect(files.path(File.join('docs', '.', 'index.html'))).to eq(File.join(destination, 'docs', 'index.html'))
		end
	end

	it 'lists output and source files relative to their roots' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(File.join(source, 'docs'))
			FileUtils.mkdir_p(File.join(destination, 'docs'))
			File.write(File.join(source, 'docs', 'source.md'), 'source')
			File.write(File.join(destination, 'docs', 'index.html'), 'output')
			File.write(File.join(destination, 'docs', 'about.html'), 'about')

			files = described_class.new(source_dir: source, dir: destination)

			expect(files.list).to eq(['docs/about.html', 'docs/index.html'])
			expect(files.list('docs')).to eq(['docs/about.html', 'docs/index.html'])
			expect(files.source_list).to eq(['docs/source.md'])
			expect(files.source_list('docs/source.md')).to eq(['docs/source.md'])
		end
	end

	it 'returns an empty list when list roots do not exist' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			files = described_class.new(source_dir: File.join(temporary_directory, 'site'), dir: File.join(temporary_directory, '_site'))
			expect(files.list('missing')).to eq([])
			expect(files.source_list('missing')).to eq([])
		end
	end

	it 'rejects paths that escape the source or output root' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			source = File.join(temporary_directory, 'site')
			destination = File.join(temporary_directory, '_site')
			FileUtils.mkdir_p(source)
			FileUtils.mkdir_p(destination)
			files = described_class.new(source_dir: source, dir: destination)

			expect { files.source_path('../outside.txt') }.to raise_error(ArgumentError)
			expect { files.path('../outside.html') }.to raise_error(ArgumentError)
		end
	end

	it 'rejects absolute unix and windows-style paths' do
		JekyllTestHarness::TemporaryDirectory.with_dir do |temporary_directory|
			files = described_class.new(source_dir: File.join(temporary_directory, 'site'), dir: File.join(temporary_directory, '_site'))

			expect { files.source_path('/etc/passwd') }.to raise_error(ArgumentError)
			expect { files.path('C:/Windows/system.ini') }.to raise_error(ArgumentError)
		end
	end
end

