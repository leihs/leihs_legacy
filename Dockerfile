# ############################################################################################### #
# Stages
# * base - Debian with OS-level dependencies
# * deps - base + application-level dependencies
# * dev - deps + dev dependencies
# * app - prod image for running the app
# ############################################################################################### #

# NOTE: the `slim` image variants are smaller, but we need to install development headers (libxml, libyaml, ssl, …) ourselves.
#       right now both works, but if gems are added one needs to hunt down what to `apt-get install` so bundle install works…
#       current comparison 1.78GB vs 1.46GB (via $ docker inspect docker.io/library/leihs-legacy | grep Size)
ARG NODEJS_VERSION=16-bullseye
# like current version in prod and CI:
# ARG RUBY_VERSION=2.6-bullseye
# more current version as used in database module:
ARG RUBY_VERSION=2.7.6-bullseye

# === STAGE: BASE NODEJS ======================================================================== #
FROM node:${NODEJS_VERSION} as leihs-base-nodejs

# === STAGE: BASE RUBY ========================================================================== #
FROM ruby:${RUBY_VERSION} as leihs-base-ruby

# === STAGE: BASE =============================================================================== #
FROM leihs-base-ruby as base

# configure OS
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# install ruby deps
RUN apt-get update -qq \
    && echo "for compiling native gems etc" \
    && apt-get install -y build-essential git \
    && echo "for nokogiri" \
    && apt-get install -y libxml2-dev libxslt1-dev \
    && echo "for mimemagic" \
    && apt-get install -y shared-mime-info \
    && echo "for postgres" \
    && apt-get install -y libpq-dev postgresql-client

RUN echo 'gem: --no-document' >> /usr/local/etc/gemrc
RUN gem update --system

# "merge" in nodejs installation from offical image (matching debian version).
COPY --from=leihs-base-nodejs /usr /usr/
# smoke check
RUN node --version && npm --version

# aliases
RUN echo -e '#!/bin/sh\nbundle exec $*' > /usr/local/bin/be && chmod +x /usr/local/bin/be
RUN cp /usr/local/bin/be /usr/local/bin/bx

# === STAGE: DEPS =============================================================================== #
FROM base as deps

ARG WORKDIR=/leihs/legacy
RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

# ruby gems
RUN echo 'gem: --no-document' >> /usr/local/etc/gemrc
COPY Gemfile* ./
COPY database/Gemfile* ./database/
# NOTE: maybe below can be optimized? like: COPY engines/leihs_admin/Gemfile* engines/leihs_admin/leihs_admin.gemspec engines/leihs_admin/lib ./engines/leihs_admin/
COPY engines/leihs_admin ./engines/leihs_admin

RUN bundle config --local path 'vendor/bundle'
RUN bundle config --local without 'development'
RUN bundle install

# NOT NEEDED, node_modules are checked into repo (submodule), and should be mounted when running (`docker run -v "${PWD}:/leihs/legacy/node_modules"`)
# # npm packages
# COPY package.json yarn.lock ./
# RUN npm ci

# === STAGE: DEV =============================================================================== #
FROM deps as dev

# ruby gems: install dev dependencies
RUN bundle config --local without ''
RUN bundle install

# === STAGE: APP =============================================================================== #
FROM deps as app

# NOTE: only be needed for `app` image, in `dev` we mount files from host
COPY . $APP_HOME

RUN bundle config --local without 'development test'
RUN bundle install

# git info, pass through from build args to environment variables. can be read from inside the container, and its also visible from outside via image inspect.
ARG GIT_COMMIT_ID
ARG GIT_SHORT_COMMIT_ID
ARG GIT_TREE_ID
ARG GIT_SHORT_TREE_ID
ENV GIT_COMMIT_ID=${GIT_COMMIT_ID}
ENV GIT_SHORT_COMMIT_ID=${GIT_SHORT_COMMIT_ID}
ENV GIT_TREE_ID=${GIT_TREE_ID}
ENV GIT_SHORT_TREE_ID=${GIT_SHORT_TREE_ID}

# config
ARG PORT=3000
ENV RAILS_ENV=production
ENV LEIHS_LEGACY_HTTP_PORT=${PORT}
EXPOSE 3000

RUN mkdir -p tmp/pids

# NOTE: this can be overriden when running, via `docker run --command` or docker compose file `service.command` entry.
CMD bundle exec puma -e production -t 1:2 -w 2 -b tcp://0.0.0.0:${LEIHS_LEGACY_HTTP_PORT}
