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

## Docker usage

Build and run bash in the base image, for example to run `bundle update` in linux to update files in local repo.
Set `STAGE` to `deps` to also include gems, `dev` for dev dependencies as well and `app` for a "production" image.
Leave out the command at the end to run the default (starting the rails server for `app` stage).

```bash
STAGE=base; # or: deps dev app
docker buildx build --target "$STAGE" -t "leihs-legacy-${STAGE}" -f Dockerfile . && \
docker run --rm -it  -v ${PWD}/:/leihs/legacy/ --workdir /leihs/legacy "leihs-legacy-${STAGE}" /bin/bash
```

### debugging

```bash
# run a base ruby container to try out something. will self-delete on exit.
docker run --rm -it  -v ${PWD}/:/leihs/legacy --workdir /leihs/legacy ruby:2.7.5-bullseye /bin/bash
# or with the leihs app inside:
```
