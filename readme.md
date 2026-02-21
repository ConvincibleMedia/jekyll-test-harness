# jekyll-test-harness

`jekyll-test-harness` is a reusable integration harness for Jekyll plugin authors. It builds a real temporary Jekyll site in your tests, loads your plugin code, and lets you assert against both in-memory Jekyll objects and generated output files.

## Why this gem exists

- Plugin specs should exercise the true Jekyll build pipeline.
- Temporary sites should be isolated and deterministic.
- Shared harness logic should stay generic, while plugin fixtures stay in each plugin project.
- You can use either RSpec or Minitest; this gem does not assume one framework.

## Minimal setup

### 1. Add dependencies

```ruby
# Gemfile
group :test do
  gem 'rspec', '~> 3.13'
  gem 'jekyll-test-harness'
end
```

### 2. Configure RSpec (load order matters)

```ruby
# spec/spec_helper.rb
require 'rspec'
require 'jekyll_test_harness/rspec'
require 'my_plugin'

RSpec.configure do |config|
  Jekyll::TestHarness::RSpec.configure(config)
end
```

### 2b. Configure Minitest (load order matters)

```ruby
# test/test_helper.rb
require 'minitest/autorun'
require 'jekyll_test_harness/minitest'
require 'my_plugin'

Jekyll::TestHarness::Minitest.configure
```

`Jekyll::TestHarness::RSpec.configure` expects RSpec to be available.
`Jekyll::TestHarness::Minitest.configure` expects `Minitest::Test` to be available.
If your test runner setup is custom, load your framework first, then call the harness configure method.

### 3. Build a site in a spec

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
      post = site.collections.fetch('posts').docs.first
      html = paths.read_output('docs/demo.html')
      expect(post).not_to be_nil
      expect(html).to include('Hello')
    end
  end
end
```

## Core API reference

### `Jekyll::TestHarness::SiteHarness.with_site`

```ruby
Jekyll::TestHarness::SiteHarness.with_site(
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

- `'source'` and `'destination'` are set to temporary directories.
- `'quiet' => true`
- `'incremental' => false`

Default scaffold (`default_scaffold: true`):

- `_layouts/default.html`
- `index.md`

### `Jekyll::TestHarness::SiteHarness.merge_data(base, overrides)`

Deep-merges hashes recursively. Scalar and array values are replaced by `overrides`.

### Paths helper

The `paths` object yielded from `with_site` exposes:

- `source`
- `destination`
- `source_path(relative_path)`
- `output_path(relative_path)`
- `read_source(relative_path)`
- `read_output(relative_path)`

### RSpec helper DSL

When configured via `Jekyll::TestHarness::RSpec.configure(config)`, specs can call:

- `build_jekyll_site(...) { |site, paths| ... }`
- `merge_jekyll_data(base, overrides)`

### Minitest helper DSL

When configured via `Jekyll::TestHarness::Minitest.configure`, tests can call:

- `build_jekyll_site(...) { |site, paths| ... }`
- `merge_jekyll_data(base, overrides)`

## Plugin-specific fixtures

Keep plugin-specific helpers, matchers, and fixtures in your plugin project (for example under `spec/support` and `spec/fixtures`). This gem should remain plugin-agnostic.

## Troubleshooting

- If build logs are too noisy, keep the default `'quiet' => true`.
- If a build fails, `SiteBuildError` includes source/destination paths and a config snapshot.
- Use `keep_site_on_failure: true` to retain temporary files for local debugging.
