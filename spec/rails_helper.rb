ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'active_record'
require 'active_support/all'
require 'rspec/rails'

# requires `rake db:environment:set` which doesn't work out-of-the-box on CI
# ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.include Rails.application.routes.url_helpers

end
