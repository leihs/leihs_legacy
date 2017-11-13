
# Frontend

Install needed dependencies:

- [`node.js`](https://nodejs.org/en/download/), e.g. `brew install nodejs`
- [`yarn`](https://yarnpkg.com/en/docs/install), e.g. `npm i -g yarn`

## Precompilation

Shortcut: If you changed the assets and just want the CI to be green:
`./bin/precompile-and-amend-assets && git push -f`

## Frontend-Dev

Optionally webpack can run alongside rails, to compile files on change
instead of on request (faster).
This is recommended when working on JS/Frontend primarily:

run `./bin/webpack-dev-server` before starting `./bin/rails server`


## Linter/Formatting Helpers

Atom:

atom-prettier w/ default settings

Vim:

prettier plugin
