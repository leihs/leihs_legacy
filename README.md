# leihs

This is the main component of [leihs](https://github.com/leihs). See the
super project [leihs/leihs](https://github.com/leihs/leihs) for more
information.

# Frontend

Install needed dependencies:

- [`node.js`](https://nodejs.org/en/download/), see `asdf` and `asdf nodejs`
- [`yarn`](https://yarnpkg.com/en/docs/install), e.g. `npm i -g yarn`

## Precompilation

Shortcut: If you changed the assets and just want the CI to be green:
`./bin/precompile-and-amend-assets && git push -f`

## Frontend-Dev

Optionally webpack can run alongside rails, to compile files on change
instead of on request (faster).
This is recommended when working on JS/Frontend primarily:

**run `./bin/webpack-dev-server` before starting `./bin/rails server`**

## Recipe to update NPM packages (2025)

The install scripts of the dependencies most likely won't run and also should not be run for security reasons, so we use `--ignore-scripts`. This mean means we have to run our own pre- and post-install scripts manually on the CLI. 

These pre- and post-install scripts are required because `yarn install` removes the `.git` file inside `node_modules`, but that file must remain in place since the directory is tracked as a Git submodule.

So what to do?

First change the package version in package.json

Then run the following on CLI:

```sh
rm -rf tmp/node_modules_git ; cp -R node_modules/.git tmp/node_modules_git
yarn install --ignore-scripts
rm -rf node_modules/.git ; cp -R tmp/node_modules_git node_modules/.git
```
