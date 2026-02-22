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

After calling `install!`, your examples/tests get:

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
      # site = the actual in-memory Jekyll site just built
      # paths = 
      post = site.collections.fetch('posts').docs.first
      html = paths.read_output('docs/demo.html')
      expect(post).not_to be_nil
      expect(html).to include('Hello')
    end
  end
end
```

### `build_jekyll_site`

Builds a fresh throwaway Jekyll site for one test example, runs a real Jekyll build (`Jekyll::Site#process`), then yield both the built `site` object and a `paths` object representing the files built.


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

Default config baseline:

- `'source'` and `'destination'` are temporary paths
- `'quiet' => true`
- `'incremental' => false`

Default scaffold (`default_scaffold: true`):

- `_layouts/default.html`
- `index.md`

### `merge_jekyll_data(base, overrides)`

A simple implementation of a deep hash merge is provided as a useful helper. This could be used to vary a base set of files or config, for instance.

### `paths` Object

The yielded `paths` object exposes:

- `source`
- `destination`
- `source_path(relative_path)`
- `output_path(relative_path)`
- `read_source(relative_path)`
- `read_output(relative_path)`