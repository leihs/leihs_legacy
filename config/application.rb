require_relative 'boot'
require_relative('../lib/leihs/middleware/audit.rb')

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Leihs
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    #
    config.i18n.enforce_available_locales = false
    # The *correct* way to do this is this:
    # config.i18n.enforce_available_locales = true
    # config.i18n.available_locales = %i(de-CH en-GB en-US en es fr-CH gsw-CH)
    # But the Faker gem is currently broken and does not accept properly spelled locales like 'en_US', it tries
    # to look for 'en' and that breaks. If Faker is ever fixed, we can uncomment the above lines.

    config.logger = ActiveSupport::Logger.new(STDOUT) unless Rails.env.development?

    if ENV['RAILS_LOG_LEVEL'].present?
      config.log_level = ENV['RAILS_LOG_LEVEL']
    else
      config.log_level = :info
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.active_record.belongs_to_required_by_default = false
    config.active_record.schema_format = :sql
    config.active_record.timestamped_migrations = false

    config.gettext_i18n_rails.use_for_active_record_attributes = false

    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('database/lib')

    config.middleware.insert_before ActionDispatch::ShowExceptions, Leihs::Middleware::Audit

    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess,
                                                          Date]
  end
end

PER_PAGE = 20
