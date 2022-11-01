#!/usr/bin/env bash
set -eu

RAILS_ENV=test bundle exec rails runner ''

if [ $(RAILS_ENV=test bundle exec rails runner '' 2>&1 | wc -l) -gt 0 ]; then
  exit 1;
else
  exit 0;
fi
