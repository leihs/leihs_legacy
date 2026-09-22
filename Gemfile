eval_gemfile Pathname(File.dirname(File.absolute_path(__FILE__))).join("database", "Gemfile")

gem "puma", "~> 7.0"
gem "puma_worker_killer"
gem "connection_pool", "< 3.0"

gem "caxlsx"
gem "barby", "~> 0.5.0"
gem "chunky_png", "~> 1.2"
gem "cider_ci-open_session", "~> 2.0.1"
gem "coffee-rails", "~> 5"
gem "coffee-script", "~> 2.2"
gem "execjs", "~> 2.6"
gem "font-awesome-sass", "~> 4.4" # NOTE font not found using gem 'rails-assets-font-awesome'
# gem 'geckodriver-helper', git: 'https://github.com/leihs/geckodriver-helper'
gem "geocoder", "~> 1.1"
gem "gettext_i18n_rails", "~> 1.0"
gem "haml", "~> 5"
gem "jquery-tmpl-rails", "~> 1.1"
gem "json", "~> 2"
gem "jsrender-rails", git: "https://github.com/leihs/jsrender-rails", branch: "rails8"
gem "kramdown" # markdown rendering
gem "kramdown-parser-gfm"
gem "liquid", "~> 5.0"
gem "net-ldap", require: "net/ldap"
gem "nilify_blanks", "~> 1.1"
gem "presentoir", git: "https://github.com/leihs/presentoir", ref: "1f65b6a673be93f9babb17f26f3bacaf64a7fbc2"
gem "rails_autolink", "~> 1.0"
gem "rake" # So that cronjobs work -- otherwise they can't find rake
gem "rinku", "~> 2.0.4", require: false
gem "rgl", "~> 0.4.0", require: "rgl/adjacency" # use ruby-graphviz instead ?? (already in test group)
gem "ruby_parser", "~> 3.1" # gettext dependency that Bundler seems unable to resolve
gem "sass-rails", "~> 5.0"
gem "uglifier", "~> 2.4"
gem "will_paginate", "~> 3.0"

# JavaScript / Frontend / Client [modern]
gem "webpacker", "~> 5.0"
gem "react-rails", "~> 2.0"

# NOTE: The frontend libraries that used to be sourced from rails-assets.org
# are now provided via npm/webpack (jquery, jquery-ui, jquery-ujs,
# jquery.inview, jquery-autosize, moment, underscore, accounting) or vendored
# directly (fullcalendar 1.6.7, jquery.inview, timecop, jquery-ui theme CSS).
# bootstrap, select2 and moment-range were unused and dropped.

group :development do
  # gem 'metric_fu'
  gem "traceroute"
  gem "web-console"
  # gem 'web-console', '~> 2.0' # Access an IRB console on exception pages or by using <%= console %> in views
end

group :test do
  gem "image_processing", "~> 1.2"
  gem "open4"
  gem "turnip"
  gem "mail"
end

group :development, :test do
  gem "cucumber-rails", "~> 4.0", require: false # it already includes capybara # NOTE '~> 1.4' doesn't work beacause 'gherkin'
  # gem 'cucumber-rails', require: false
  # gem 'cucumber', '~> 3'
  # gem 'capybara', '3.36.0'
  gem "selenium-webdriver", "~> 4.1"

  gem "solargraph"
  gem "solargraph-rails"

  gem "bootsnap"

  gem "database_cleaner"
  gem "factory_bot_rails", "~> 6"
  gem "flog"
  gem "flay"

  gem "pry-nav"
  gem "pry-rails"

  gem "rb-readline"
  gem "rspec-rails", "~> 7", require: false
  # gem 'selenium-webdriver', '~> 3.14'
  gem "spring" # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "timecop", "~> 0.7"
end
