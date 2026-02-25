# Rails 8 Asset Upgrade Notes

This document summarizes the observed asset behavior after upgrading from Rails 7.2 to Rails 8.0 in `leihs_legacy`.

## Short answer

- `public/assets/packs` is still required in the current setup.
- `./bin/recompile-assets` does compile both webpack packs:
  - `application`
  - `server_rendering`
- Rails 8 may produce additional digested framework assets in `public/assets` (outside `packs/`), which is expected.

## Why `public/assets/packs` is still needed

Current app wiring still uses Webpacker:

- `javascript_pack_tag 'application'` is used in `app/views/layouts/_head.html.haml`.
- `app/javascript/packs/application.js` exists as a pack entrypoint.
- `app/javascript/packs/server_rendering.js` exists for React server rendering.
- `config/webpacker.yml` sets:
  - `public_output_path: assets/packs`

Therefore webpack output must continue to exist under `public/assets/packs`.

## Verified `recompile-assets` behavior

`bin/recompile-assets` runs:

1. `npm ci --ignore-scripts`
2. `bundle exec rake app:i18n:po2json`
3. `bundle exec rake webpacker:clobber assets:precompile assets:clean`

Observed compile output confirms both entries are built:

- `js/application-505c2038614e5ee6160a.js`
- `js/server_rendering-73fdbf6e1f80d0d5ba23.js`

And `public/assets/packs/manifest.json` maps:

- `application.js` -> `/assets/packs/js/application-...`
- `server_rendering.js` -> `/assets/packs/js/server_rendering-...`

## Commit comparison (assets submodule)

Compared:

- old: `129ff7c9f46559c48e562bfd358e7b2c72d8f21d`
- new: `8673672428ca91969199a7f230abbf3600c599c4`

### Expected changes

- Pack digest rollover:
  - `application-77bb...` -> `application-505c...`
  - `server_rendering-5e6f...` -> `server_rendering-73fd...`
- `packs/manifest.json` updated to new digests.

### New files that looked unusual but are expected

New Rails framework asset variants were added in the new commit:

- `actiontext-9ccbf...` (+ `.gz`)
- `actiontext.esm-6790...` (+ `.gz`)
- `activestorage-cf22...` (+ `.gz`)
- `activestorage.esm-8bb0...` (+ `.gz`)

These are framework-managed assets emitted by precompile and are normal after framework/version changes.

### Trix digest changes

- Added:
  - `trix-227b...js` (+ `.gz`)
  - `trix-4e07...css` (+ `.gz`)
- Removed:
  - `trix-d24a...js` (+ `.gz`)
  - `trix-83cb...css` (+ `.gz`)

This is standard digest churn.

## Rails 7.2 vs 8.0 behavior summary

- Webpacker pack generation behavior in this app remains functionally the same.
- Difference in Rails 8 is mostly additional/updated Sprockets framework outputs (ActionText/ActiveStorage/Trix digests).
- Seeing more framework files in `public/assets` does not mean packs are obsolete.

## Troubleshooting checklist

If someone thinks packs are missing:

1. Check correct location: `public/assets/packs/js` (not `public/packs/js`).
2. Verify `public/assets/packs/manifest.json` contains both `application.js` and `server_rendering.js`.
3. Re-run `./bin/recompile-assets` and inspect for:
   - `Compiled all packs ...`
   - both entrypoints listed.
4. Remember digest names only change when content changes; same digest can be valid after recompile.
