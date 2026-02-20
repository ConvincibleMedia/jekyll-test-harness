# Jekyll Test Harness Specification

## 1. Purpose

Create a reusable gem (`jekyll-test-harness`) that Jekyll plugin authors can add as a development dependency so their RSpec suite can build and process a real temporary Jekyll site with the plugin loaded.

The harness must make integration testing easy, deterministic, and plugin-agnostic while keeping plugin-specific fixtures and helpers inside each plugin project.

## 2. Current State Review

The repository already contains a mostly generic harness in `example/support/jekyll`:

- `site_harness.rb` builds a temporary site, writes `_config.yml` and files, then runs `Jekyll::Site#process`.
- `file_tree.rb` writes nested file hashes.
- `temporary_directory.rb` manages temporary directories.

Current limitations that block extraction:

- Generic code lives under `example/` instead of `lib/`.
- `spec/support/spec_helper.rb` and most specs are coupled to `jekyll-asset_manager`.
- There is duplicated utility code in `example/support/test_support/file_tree.rb`.
- There is no consumer-facing API contract yet for third-party plugin projects.
- There is no test suite that validates the real "plugin developer uses this gem with RSpec" scenario end-to-end.

## 3. Goals

1. Provide a stable public API for building temporary Jekyll sites in specs.
2. Keep the gem strictly plugin-agnostic.
3. Make defaults minimal but useful (site scaffold, quiet output, isolation).
4. Provide RSpec integration helpers that are optional and lightweight.
5. Offer strong diagnostics when Jekyll build failures happen.
6. Ensure deterministic cleanup, with opt-in retention for debugging failures.
7. Fully test the gem using real RSpec + Jekyll runs, including consumer simulation.

## 4. Non-Goals

- Replacing plugin-specific fixture helpers (those remain in each plugin project).
- Mocking Jekyll internals instead of running the true build pipeline.
- Providing Minitest support in the first release (RSpec first; extensible later).

## 5. Proposed Gem Architecture

### 5.1 File Layout

```text
lib/
  jekyll/
    test_harness.rb
    test_harness/version.rb
    test_harness/site_harness.rb
    test_harness/file_tree.rb
    test_harness/temporary_directory.rb
    test_harness/paths.rb
    test_harness/errors.rb
    test_harness/rspec.rb
    test_harness/configuration.rb
```

### 5.2 Module Names

- Primary namespace: `Jekyll::TestHarness`
- Core builder: `Jekyll::TestHarness::SiteHarness`
- Utilities: `FileTree`, `TemporaryDirectory`, `Paths`
- RSpec integration: `Jekyll::TestHarness::RSpec`

Keep naming human-readable and explicit.

## 6. Public API Design

### 6.1 Core API

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

Behaviour:

- Creates an isolated temporary directory per example.
- Writes merged config to `_config.yml`.
- Writes merged file tree to the temporary source directory.
- Runs `Jekyll::Site#process`.
- Yields built `site` and a `paths` helper object.
- Cleans up temporary directories unless retention is requested.

### 6.2 Helper Methods

- `Jekyll::TestHarness::SiteHarness.merge_data(base, overrides)`
  - Deep-merge hashes.
  - Scalar and array values are replaced by `overrides`.
- `Jekyll::TestHarness::FileTree.write(root, files)`
  - Writes nested hash trees.
- `Jekyll::TestHarness::FileTree.write_yaml(path, data)`
- `Jekyll::TestHarness::TemporaryDirectory.with_dir(prefix:)`

### 6.3 Paths Helper

`paths` should expose:

- `source`
- `destination`
- `read_output(relative_path)`
- `read_source(relative_path)`
- `output_path(relative_path)`
- `source_path(relative_path)`

### 6.4 RSpec Integration API

Consumer usage:

```ruby
# spec/spec_helper.rb
require 'jekyll_test_harness/rspec'
require 'my_plugin'

RSpec.configure do |config|
  Jekyll::TestHarness::RSpec.configure(config)
end
```

Provided DSL:

- `build_jekyll_site(...) { |site, paths| ... }` delegating to `with_site`
- `merge_jekyll_data(base, overrides)` delegating to `merge_data`

These methods reduce boilerplate but do not hide core behaviour.

## 7. Configuration and Defaults

Default config baseline:

```ruby
{
  'source' => temp_source,
  'destination' => temp_destination,
  'quiet' => true,
  'incremental' => false
}
```

Default scaffold (`default_scaffold: true`):

- `_layouts/default.html`
- `index.md`

Rationale:

- New specs can focus on plugin behaviour instead of bootstrapping a full site.
- `default_scaffold: false` allows total control when required.

## 8. Error Handling and Diagnostics

Add explicit errors in `errors.rb`:

- `Jekyll::TestHarness::Error`
- `MissingBlockError`
- `SiteBuildError`

`SiteBuildError` should include:

- Original exception (`cause`)
- Source and destination paths
- Config snapshot used for the run
- Guidance that `keep_site_on_failure: true` can preserve the directory for debugging

## 9. Generalisation Rules (Extraction Boundaries)

What belongs in this gem:

- Site lifecycle, file writing, merging helpers, path helpers, RSpec glue.

What does not belong:

- Any plugin-specific fixtures, matchers, helper modules, or assumptions about config keys beyond standard Jekyll config.

Migration action:

- Remove `example/support/asset_manager_support.rb` and all plugin-specific specs from this gem.
- Replace with harness-focused specs using fixture plugins.
- Remove duplicate `example/support/test_support/file_tree.rb`.

## 10. Implementation Plan

1. Create `lib/jekyll_test_harness/...` structure and move generic harness code from `example/support/jekyll`.
2. Introduce `version.rb` and entrypoint file (`lib/jekyll_test_harness.rb`) requiring public components.
3. Refactor `SiteHarness`:
   - Add options `default_scaffold` and `keep_site_on_failure`.
   - Improve failure reporting with `SiteBuildError`.
4. Expand `Paths` helper with source/output path helpers and readers.
5. Keep `merge_data` as a stable public utility; document merge semantics clearly.
6. Add RSpec integration module (`lib/jekyll_test_harness/rspec.rb`) exposing DSL helpers.
7. Update gemspec `spec.files` to include all `lib/**/*.rb` and supporting docs.
8. Write README quick start for plugin authors, including minimal `spec_helper.rb`.
9.  Implement comprehensive tests (see section 11).
10. Validate on at least Ruby and Jekyll versions declared in gemspec support.

Following implementation, ./example will be deleted.

## 11. Testing Strategy for This Gem

The test strategy must prove both internals and real consumer workflow.

### 11.1 Test Layers

1. Unit tests
   - `merge_data` behaviour (nested hashes, nil handling, scalar replacement).
   - `FileTree.write` and `write_yaml`.
   - `TemporaryDirectory.with_dir` cleanup behaviour.
   - `Paths` helper read/path methods.

2. Integration tests (in-process)
   - Use a fixture plugin required into the spec process.
   - Build real Jekyll sites with `with_site`.
   - Assert in-memory document data and rendered HTML output.
   - Assert hook execution and Liquid tag output.

3. Consumer simulation tests (subprocess, critical)
   - Create a temporary fake plugin project during the spec.
   - Write:
     - `Gemfile` including `jekyll-test-harness` via local `path:`.
     - `lib/<plugin>.rb` (minimal plugin with hook + tag).
     - `spec/spec_helper.rb` requiring `jekyll_test_harness/rspec` and plugin.
     - `spec/integration_spec.rb` using harness DSL.
   - Run `bundle exec rspec` inside that temporary project.
   - Assert exit status `0` and expected spec output.
   - This verifies the exact scenario: "I am developing a plugin and running RSpec using this gem."

4. Failure-path integration tests
   - Force build errors (invalid config, broken Liquid, missing include).
   - Assert raised `SiteBuildError` contains useful diagnostic context.
   - Assert temp directory preservation when `keep_site_on_failure: true`.

5. Compatibility tests
   - Run suite against supported Jekyll versions (for example via Appraisal).
   - Run CI on Linux and Windows to catch path separator issues.

### 11.2 Fixture Plugin Design for Tests

Use small internal fixture plugins under `spec/fixtures/plugins/`:

- `hook_plugin`: adds document data during `:documents, :pre_render`.
- `tag_plugin`: defines a simple Liquid tag that renders predictable output.
- `generator_plugin` (optional): writes a generated page to test broader integration.

Each fixture must be tiny and deterministic to keep tests fast.

### 11.3 Consumer Simulation Details

The consumer simulation is the key acceptance test:

1. Test creates temporary project folder.
2. Writes plugin and spec files as a real plugin author would.
3. Installs dependencies.
4. Executes `bundle exec rspec`.
5. Asserts:
   - Harness loads from gem path.
   - Site builds successfully.
   - Plugin behaviour appears in output and/or page data.
   - RSpec exits successfully.

Also add one negative consumer simulation:

- Intentional failure in spec to confirm failure output is readable and references harness APIs correctly.


## 12. Documentation Requirements

README must include:

- Why this gem exists.
- Minimal setup in a plugin project (`Gemfile`, `spec_helper`, example spec).
- API reference for `with_site`, `merge_data`, and RSpec DSL.
- Guidance for plugin-specific fixture modules.
- Troubleshooting section for common Jekyll build failures.

## 13. Definition of Done

This specification is complete when:

1. Harness code is implemented at `lib/` and is plugin-agnostic.
2. Public API is documented and stable.
3. Plugin-specific legacy specs are replaced with harness-focused tests.
4. Consumer simulation tests prove real plugin-author workflow via `bundle exec rspec`.