# Rails 8 Upgrade: Relevant Information

This note captures the key technical details of the Rails 7.2 -> 8.0 upgrade for `leihs_legacy` (main app + `database` submodule).

## Scope

- Main app: `/Users/mradl/2026_02/leihs_legacy`
- Database submodule: `/Users/mradl/2026_02/leihs_legacy/database`
- Asset submodule behavior validated separately (see `doc/rails8-assets-upgrade-notes.md`).

## Core version changes

- Rails constraint moved to `~> 8.0.0` (in `database/Gemfile`).
- Lockfiles resolved to Rails `8.0.4`:
  - `Gemfile.lock`
  - `database/Gemfile.lock`
- Ruby toolchain aligned to `3.3.8` in root `.tool-versions` to match upgrade baseline.

## Custom dependency updates (blockers removed)

- `jsrender-rails` moved from `rails7` branch to `rails8` branch.
- `pg_tasks` (`rails_pg-tasks`) moved from `rails7` branch to `rails8` branch.
- `cucumber-rails` updated from `~> 2.5` to `~> 4.0` for Rails 8 compatibility.
- `connection_pool` constrained to `< 3.0` due to `react-rails` compatibility during boot.

## Framework default/config updates

- `config.load_defaults` changed from `7.2` to `8.0` in:
  - `config/application.rb`
  - `database/config/application.rb`
- Added Rails 8 default initializer stubs:
  - `config/initializers/new_framework_defaults_8_0.rb`
  - `database/config/initializers/new_framework_defaults_8_0.rb`

## Testing and verification outcomes

### Passing checks

- `database/bin/rspec --fail-fast`
  - Passed (`27 examples, 0 failures`)
- `bin/rspec spec/models --fail-fast`
  - Passed (`23 examples, 0 failures, 2 pending`)
- `bin/cucumber features/login/login.feature`
  - Passed (`1 scenario, 1 passed`)

### Notable issues encountered and handled

- Missing helper script in local environment:
  - `~/.claude/scripts/reload-backend-test.sh` not found.
- DB env extraction script produced noisy output under Rails 8:
  - `database/bin/db-set-env` adjusted to robustly extract JSON from `rails runner` output.
- Turnip step discovery issues after dependency changes:
  - Test setup adjusted to require Turnip helper and step files from `spec/steps`.
- One pre-existing feature-spec data/path issue remained:
  - `spec/features/availability_example.feature` references missing data files under documentation path.
  - This is separate from pack compilation and core Rails boot.

## Assets behavior summary after upgrade

- `./bin/recompile-assets` still builds webpack packs (`application`, `server_rendering`).
- `public/assets/packs` is still required in current architecture (`javascript_pack_tag`, Webpacker config, React SSR pack).
- Rails 8 precompile emits additional framework digests in `public/assets` (e.g. `actiontext`, `activestorage`, `trix` churn), which is expected.

## Operational notes for team

- Do not remove `public/assets/packs` unless frontend pipeline is intentionally migrated away from Webpacker and all references are updated.
- Digest filenames changing (or remaining unchanged) across recompiles is normal and content-driven.
- Keep both lockfiles (`Gemfile.lock` and `database/Gemfile.lock`) in sync with dependency branch changes for reproducibility.

## Quick sanity checklist after pulling upgrade branch

1. `bundle install` in both root and `database` contexts if needed.
2. Confirm Ruby version is `3.3.8` via asdf.
3. Run `./bin/recompile-assets` and verify both pack entrypoints in `public/assets/packs/manifest.json`.
4. Run targeted smoke tests:
   - `database/bin/rspec --fail-fast`
   - `bin/rspec spec/models --fail-fast`
   - `bin/cucumber features/login/login.feature`
