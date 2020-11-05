require 'pry'
require 'turnip/capybara'
require 'rails_helper'
require 'factory_girl'
require 'config/database.rb'

class Object
  alias_method :ivar_get, :instance_variable_get
  alias_method :ivar_set, :instance_variable_set
end

if ENV['FIREFOX_ESR_45_PATH'].present?
  Selenium::WebDriver::Firefox.path = ENV['FIREFOX_ESR_45_PATH']
end

[:firefox].each do |browser|
  Capybara.register_driver browser do |app|
    Capybara::Selenium::Driver.new app, browser: browser
  end
end

Capybara.configure do |config|
  config.server = :puma
  config.default_max_wait_time = 15
end

RSpec.configure do |config|

  config.raise_error_for_unimplemented_steps = true

  config.include Rails.application.routes.url_helpers

  config.before(type: :feature) do
    PgTasks.truncate_tables()
    Config::Database.restore_seeds
    Capybara.current_driver = :firefox
    page.driver.browser.manage.window.maximize
  end

  config.after(type: :feature) do |example|
    if ENV['CIDER_CI_TRIAL_ID'].present?
      unless example.exception.nil?
        take_screenshot
      end
    end
    page.driver.quit # OPTIMIZE force close browser popups
    Capybara.current_driver = Capybara.default_driver
    # PgTasks.truncate_tables()
  end

  def take_screenshot(screenshot_dir = nil, name = nil)
    screenshot_dir ||= Rails.root.join('tmp', 'capybara')
    name ||= "screenshot_#{Time.zone.now.iso8601.gsub(/:/, '-')}.png"
    Dir.mkdir screenshot_dir rescue nil
    path = screenshot_dir.join(name)
    case Capybara.current_driver
    when :firefox
      page.driver.browser.save_screenshot(path) rescue nil
    else
      Rails
        .logger
        .warn "Taking screenshots is not implemented for \
      #{Capybara.current_driver}."
    end
  end
end
