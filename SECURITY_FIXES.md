# Security Vulnerability Fixes

## Resolved

### High Severity

| # | Package | Source | Vulnerability | CVE | Fix |
|---|---------|--------|---------------|-----|-----|
| #457 | rack (RubyGems) | Gemfile.lock | Directory Traversal via Rack::Directory | CVE-2025-27610 | 2.2.21 → 2.2.22 |
| #450 | tar (npm) | package-lock.json | Arbitrary File Overwrite & Symlink Poisoning via Insufficient Path Sanitization | CVE-2026-23745 | 6.2.1 → 7.5.9 (override) |
| #451 | tar (npm) | package-lock.json | Race Condition in Path Reservations via Unicode Ligature Collisions on macOS APFS | CVE-2026-23950 | 6.2.1 → 7.5.9 (override) |
| #454 | tar (npm) | package-lock.json | Arbitrary File Creation/Overwrite via Hardlink Path Traversal | CVE-2026-24842 | 6.2.1 → 7.5.9 (override) |
| #459 | tar (npm) | package-lock.json | Arbitrary File Read/Write via Hardlink Target Escape Through Symlink Chain | — | 6.2.1 → 7.5.9 (override) |

### Moderate Severity

| # | Package | Source | Vulnerability | CVE | Fix |
|---|---------|--------|---------------|-----|-----|
| #452, #453 | lodash (npm) | package.json, package-lock.json | Prototype Pollution in `_.unset` and `_.omit` | CVE-2025-13465 | 4.17.21 → 4.17.23 |
| #431 | node-forge (npm) | package-lock.json | Open Redirect | — | 0.10.0 → 1.3.3 (override) |
| #434 | node-forge (npm) | package-lock.json | Improper Verification of Cryptographic Signature | — | 0.10.0 → 1.3.3 (override) |
| #447 | node-forge (npm) | package-lock.json | ASN.1 OID Integer Truncation | CVE-2025-12816 | 0.10.0 → 1.3.3 (override) |
| #458 | rack (RubyGems) | Gemfile.lock | Stored XSS in Rack::Directory via javascript: filenames | CVE-2026-25500 | 2.2.21 → 2.2.22 |

## Unresolved — Requires Webpack 5 Migration

The following moderate-severity alerts are all rooted in the webpack 4 / webpacker 5 dependency tree. Their fix versions involve incompatible major version jumps that would break the current build. Resolving them requires migrating from webpacker 5 (webpack 4) to a modern bundler setup (e.g. jsbundling-rails with webpack 5 or esbuild).

| # | Package | Current | Fix Version | Blocker |
|---|---------|---------|-------------|---------|
| #444 | webpack-dev-server | 3.11.3 | ≥ 5.2.1 | Requires webpack 5; no 3.x/4.x patch exists |
| — | webpack-dev-server | 3.11.3 | ≥ 5.2.1 | Same as above (second alert, non-Chromium variant) |
| #456 | ajv | 6.12.6 | ≥ 8.18.0 | Major API change; schema-utils depends on ajv 6.x |
| #436 | postcss | 7.0.39 | ≥ 8.4.31 | Major API change; css-loader 3.x depends on postcss 7.x |
| #440 | micromatch | 3.1.10 | ≥ 4.0.8 | No 3.x patch; webpack 4 core depends on micromatch 3.x |

### Risk Assessment for Unresolved Alerts

- **webpack-dev-server**: Dev-only tool, not deployed to production. Attack requires developer to visit a malicious site while the dev server is running.
- **ajv**: ReDoS only exploitable when the `$data` option is enabled. In this project ajv is used by schema-utils to validate webpack configs (trusted input), not user-supplied data.
- **postcss**: Parsing error only affects processing of untrusted external CSS. This project only processes its own stylesheets.
- **micromatch**: ReDoS via `braces()` only affects untrusted glob patterns. This project only uses micromatch with hardcoded config patterns.

### Recommended Path Forward

Migrate from `@rails/webpacker` 5.x (webpack 4) to `jsbundling-rails` with webpack 5 or esbuild. This would allow all transitive dependencies to update to their current major versions, resolving the remaining alerts. This is a non-trivial effort involving:

1. Replacing webpacker configuration with webpack 5 config or esbuild
2. Updating css-loader, postcss, and related loaders to current versions
3. Replacing webpack-dev-server 3.x with 5.x (or using esbuild's built-in server)
4. Verifying all React components and CoffeeScript assets compile correctly
