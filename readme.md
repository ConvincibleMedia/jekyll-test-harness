# Jekyll Test Harness

A test harness for testing Jekyll plugins. The goal is that you can incorporate this gem as a development dependency, enabling methods in your specs that allow for testing the plugin in a test Jekyll environment.

This gem uses RSpec integration tests that build a miniature Jekyll site for each example. The goal is to exercise the real Jekyll pipeline (including hooks and Liquid rendering) while keeping every test isolated and repeatable.

## How the harness works

The test harness lives in `spec/support/jekyll/site_harness.rb` and is intentionally generic to keep it suitable for reuse in other Jekyll plugin gems later. The shared spec setup now lives in `spec/support/spec_helper.rb`.

Key points:

- `JekyllSpecSupport::SiteHarness.with_site` creates a fresh temporary site directory, writes `_config.yml` and any supplied files, runs a full `Jekyll::Site#process`, and then cleans up.
- Each example receives the built `site` plus a simple paths helper for reading files from the destination folder.
- Test files are expressed as nested hashes so specs stay compact and avoid large fixture trees.
- The harness defaults are minimal and plugin-agnostic, so plugin-specific config and files are supplied by each spec.

## Writing new tests

Guidelines for extending the suite:

- Prefer collection documents (for example, `_posts` or a custom collection) because the plugin hooks are registered on `:documents`.
- Keep each example self-contained by supplying its own config and files, then use `JekyllSpecSupport::SiteHarness.merge_data` to layer in overrides without repeating boilerplate.
- Assert against the rendered output and the in-memory `page.data['assets']` structure so both the hooks and the Liquid tag are covered.

## Notes on future abstraction

The harness is written with extraction in mind:

- It does not assume any plugin-specific config.
- It uses a small public API (`with_site`, `merge_data`) that can be moved into a shared gem with minimal change.

If multiple plugins adopt the same pattern, consider extracting to a dedicated test harness gem (for example, `jekyll-plugin-testkit`). That would centralise maintenance and let each plugin keep its specs focused on behaviour rather than boilerplate.

## Reusing the harness in a new Jekyll plugin

The Jekyll harness is designed to be portable. To use it in a different Jekyll plugin gem:

1. Copy the entire `spec/support/jekyll` folder into the new gem at `spec/support/jekyll`.
2. Copy `spec/support/spec_helper.rb` and adjust the `require 'jekyll-asset_manager'` line to the new gem’s entrypoint.
3. If you do not want any plugin-specific helpers, remove `spec/support/asset_manager_support.rb` and the `config.include` lines that reference `AssetManagerSpecSupport` in `spec/support/spec_helper.rb`.
4. In each spec file, require the shared helper with:
   ```ruby
   require_relative 'support/spec_helper'
   ```

From there you can build sites with:

```ruby
JekyllSpecSupport::SiteHarness.with_site(
  config: { 'assets' => { /* plugin config */ } },
  files:  { '_posts' => { '2026-01-01-demo.md' => '---\nlayout: default\n---\nHello' } }
) do |site, paths|
  # assertions here
end
```

If you need reusable fixtures or helpers for the new plugin, define them in a separate support file (for example, `spec/support/<plugin>_support.rb`) and include them from `spec/support/spec_helper.rb`. This keeps the Jekyll harness clean and reusable across plugins.
