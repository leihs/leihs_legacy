ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require_relative '../database/spec/config/database'


require 'active_record'
require 'active_support/all'
require 'rspec/rails'

# requires `rake db:environment:set` which doesn't work out-of-the-box on CI
# ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.include Rails.application.routes.url_helpers


  config.before(:example) do |example|
    db_clean

    case example.metadata[:db_data_seed]
    when "personas"
      db_restore_data personas_sql
    else
      db_restore_data seeds_sql
    end
  end

end
