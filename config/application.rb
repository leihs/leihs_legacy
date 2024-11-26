require_relative "boot"
require_relative("../lib/leihs/middleware/audit.rb")

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Leihs
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.i18n.enforce_available_locales = false

    config.logger = ActiveSupport::Logger.new(STDOUT) unless Rails.env.development?

    if ENV['RAILS_LOG_LEVEL'].present?
      config.log_level = ENV['RAILS_LOG_LEVEL']
    else
      config.log_level = :info
    end

    # due to host name discrepancy behind a proxy
    config.action_controller.forgery_protection_origin_check = false

    config.active_record.belongs_to_required_by_default = false
    config.active_record.schema_format = :sql
    config.active_record.timestamped_migrations = false

    config.gettext_i18n_rails.use_for_active_record_attributes = false

    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('database/lib')
    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('database/lib')

    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess,
                                                          Date]

    config.middleware.insert_after Rack::TempfileReaper, Leihs::Middleware::Audit
  end
end

PER_PAGE = 20
