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
dsafdasfdsa

### debugging

```bash
# run a base ruby container to try out something. will self-delete on exit.
docker run --rm -it  -v ${PWD}/:/leihs/legacy --workdir /leihs/legacy ruby:2.7.5-bullseye /bin/bash
# or with the leihs app inside:
```
