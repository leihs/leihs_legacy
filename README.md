# leihs

This is the main component of [leihs](https://github.com/leihs). See the
super project [leihs/leihs](https://github.com/leihs/leihs) for more
information.

# Frontend

Install needed dependencies:

- [`node.js`](https://nodejs.org/en/download/), see `asdf` and `asdf nodejs`

## Precompilation

If you changed the assets: `./bin/recompile-assets`

Before pushing, make sure to commit and push `public/assets` submodule.

## Frontend-Dev

Optionally webpack can run alongside rails, to compile files on change
instead of on request (faster).
This is recommended when working on JS/Frontend primarily:

**run `./bin/webpack-dev-server` before starting `./bin/rails server`**

## NPM (2025)

Packages are managed by NPM instead of Yarn now.
