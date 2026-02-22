# Jekyll Test Harness

Simple integration testing for Jekyll plugins. Extends RSpec or Minitest with helper methods for building a real Jekyll site, with your plugin available, to test how it actually runs within Jekyll. The generated sites are wiped for each test, and optionally kept on failure.

## Setup

```ruby
# Gemfile
group :test do
  gem 'jekyll-test-harness'
  gem 'rspec', '~> 3.13' # if using RSpec
  gem 'minitest', '>= 5.0' # if using Minitest
end
```

Load the harness into RSpec:

```ruby
# spec/spec_helper.rb
require 'rspec'
require 'jekyll_test_harness'
require 'my_plugin'

RSpec.configure do |config|
  JekyllTestHarness.install!(rspec_configuration: config)
end
```

Load the harness into Minitest:

```ruby
# test/test_helper.rb
require 'minitest/autorun'
require 'jekyll_test_harness'
require 'my_plugin'

JekyllTestHarness.install!
```

`JekyllTestHarness.install!` auto-detects which framework you are using, however if there is any ambiguity, it can be configured explicitly with its first parameter, being either `:rspec` or `:minitest`.


## Test DSL

After calling `install!`, your examples/tests get two helper methods:

- `build_jekyll_site(...) { |site, paths| ... }`
- `merge_jekyll_data(base, overrides)`

Example:

```ruby
RSpec.describe 'my plugin integration' do
  it 'renders expected output' do
    files = {
      '_layouts' => {
        'default.html' => '<html><body>{{ content }}</body></html>'
      },
      '_posts' => {
        '2026-01-01-demo.md' => "---\nlayout: default\npermalink: /docs/demo.html\n---\nHello\n"
      }
    }

    build_jekyll_site(files: files) do |site, paths|
      # site = in-memory Jekyll::Site instance for this build
      # paths = helper for reading source/output files
      post = site.collections.fetch('posts').docs.first
      html = paths.read_output('docs/demo.html')
      expect(post).not_to be_nil
      expect(html).to include('Hello')
    end
  end
end
```

### `build_jekyll_site`

Builds a fresh throwaway Jekyll site for one test example, runs a real Jekyll build (`Jekyll::Site#process`), and yields both:
- `site`: the built `Jekyll::Site` object (collections, documents, metadata, etc.)
- `paths`: file helper object for source/output assertions

```ruby
build_jekyll_site(
  config: {},
  files: {},
  base_config: {},
  base_files: {},
  default_scaffold: true,
  keep_site_on_failure: false
) do |site, paths|
  # assertions
end
```

Options:

- `config`:
  Per-example config overrides merged last.
- `files`:
  Per-example files written into the temporary source.
- `base_config`:
  Reusable baseline config for a spec group.
- `base_files`:
  Reusable baseline file tree for a spec group.
- `default_scaffold`:
  If `true`, writes a minimal working scaffold (`_layouts/default.html`, `index.md`).
- `keep_site_on_failure`:
  If `true`, keeps temporary site directories when a build fails, useful for debugging.

Default config baseline:

- `'source'` and `'destination'` are temporary paths
- `'quiet' => true`
- `'incremental' => false`

Default scaffold (`default_scaffold: true`):

- `_layouts/default.html`
- `index.md`

### `paths` Object

The yielded `paths` object exposes:

- `source`: absolute path to the temporary source directory.
- `destination`: absolute path to the temporary output directory.
- `source_path(relative_path)`:
  absolute path under `source`.
- `output_path(relative_path)`:
  absolute path under `destination`.
- `read_source(relative_path)`:
  file contents from source.
- `read_output(relative_path)`:
  file contents from output.

`relative_path` is validated to prevent path traversal outside the temporary site.

### `merge_jekyll_data(base, overrides)`

A simple implementation of a deep hash merge is provided as a useful helper. This could be used to vary a base set of files or config, for instance.