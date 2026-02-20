# Jekyll Spec Harness

This folder provides a portable test harness for Jekyll plugins. It creates a temporary site, writes files and configuration, runs a full build, and returns the built site for assertions.

The harness is intentionally plugin‑agnostic. You can copy `spec/support/jekyll` into another Jekyll plugin gem and wire it in through your own `spec/support/spec_helper.rb`.

## Contents

- `site_harness.rb` — build and render temporary Jekyll sites.
- `file_tree.rb` — write nested file trees to disk.
- `temporary_directory.rb` — create and clean up temporary directories.

## Quick Start

1. Require the harness:

```ruby
require_relative 'support/spec_helper'
```

2. Build and test a site:

```ruby
JekyllSpecSupport::SiteHarness.with_site(
  config: {
    'assets' => {
      'basepath' => '/assets/:type/:group/:package',
      'layouts' => { 'default' => { 'css' => ['layout.css'] } }
    }
  },
  files: {
    '_layouts' => { 'default.html' => '<html><body>{{ content }}</body></html>' },
    '_posts' => {
      '2026-01-01-demo.md' => "---\nlayout: default\n---\nHello"
    }
  }
) do |site, paths|
  doc = site.collections['posts'].docs.first
  html = paths.read_output(doc.url.sub(%r{^/}, ''))
  # assertions here
end
```

## API

### `JekyllSpecSupport::SiteHarness.with_site`

Builds a temporary Jekyll site and yields the site and output paths.

```ruby
JekyllSpecSupport::SiteHarness.with_site(
  config: {},      # per‑spec config overrides
  files: {},       # per‑spec files
  base_config: {}, # optional base config
  base_files: {}   # optional base file tree
) do |site, paths|
  # ...
end
```

Parameters:

- `config`: Hash merged into the base config.
- `files`: Hash of files written under the site root.
- `base_config`: Optional shared defaults for a group of specs.
- `base_files`: Optional shared file tree.

The harness always adds:

- `source` and `destination` paths.
- `quiet: true` (to reduce log noise).

### `JekyllSpecSupport::SiteHarness.merge_data`

Deep merges two hashes. Useful for layering overrides:

```ruby
config = JekyllSpecSupport::SiteHarness.merge_data(base_config, overrides)
```

### `JekyllSpecSupport::FileTree.write`

Writes a nested hash to disk.

```ruby
JekyllSpecSupport::FileTree.write(root, {
  '_layouts' => { 'default.html' => '<html></html>' },
  '_posts' => { '2026-01-01-demo.md' => '---\n---\nHello' }
})
```

### `JekyllSpecSupport::TemporaryDirectory.with_dir`

Creates and cleans up a temporary directory.

```ruby
JekyllSpecSupport::TemporaryDirectory.with_dir do |dir|
  # use dir
end
```

## File Tree Format

`files` and `base_files` are hashes:

- Keys are relative paths.
- Values are either strings (file contents) or nested hashes (directories).

Example:

```ruby
{
  '_layouts' => {
    'default.html' => '<html><body>{{ content }}</body></html>'
  },
  '_posts' => {
    '2026-01-01-demo.md' => "---\nlayout: default\n---\nHello"
  }
}
```

## Recommended Patterns

- Use `_posts` by default so documents run through `:documents` hooks.
- Keep specs isolated by passing all needed files via `files:` overrides.
- Use `base_config` and `base_files` for repeated setup within a spec group.

## Porting to Another Plugin

1. Copy `spec/support/jekyll` into the new plugin.
2. Create `spec/support/spec_helper.rb` and require the harness files:
   ```ruby
   support_root = File.expand_path(__dir__)
   Dir[File.join(support_root, 'jekyll', '**', '*.rb')].sort.each { |file| require file }
   ```
3. Require the new plugin’s entrypoint (for example, `require 'my-plugin'`).
4. In each spec file, `require_relative 'support/spec_helper'`.

If you want plugin‑specific fixtures, keep them in a separate support file and include those helpers from your `spec/support/spec_helper.rb`, leaving the harness clean and reusable.
