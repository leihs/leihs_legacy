require 'active_support/all'
require 'capybara/rspec'
require 'factory_bot'
require 'pry'
require 'rails_helper'
require 'selenium-webdriver'

require_relative '../../database/spec/config/database'

BROWSER_DOWNLOAD_DIR= File.absolute_path(File.expand_path(__FILE__)  + "./../../tmp")

class Object
  alias_method :ivar_get, :instance_variable_get
  alias_method :ivar_set, :instance_variable_set
end

module Capybara::Node::Finders
  # override due to raising an error instead of returning nil
  def first(*args, **options, &optional_filter_block)
    options = { minimum: 0 }.merge(options) unless options_include_minimum?(options)
    all(*args, **options, &optional_filter_block).first
  end
end



firefox_bin_path = Pathname.new(`asdf where firefox`.strip).join('bin/firefox').expand_path.to_s
Selenium::WebDriver::Firefox.path = firefox_bin_path

Capybara.register_driver :firefox do |app|

  profile = Selenium::WebDriver::Firefox::Profile.new
  opts = Selenium::WebDriver::Firefox::Options.new(
    binary: firefox_bin_path,
    profile: profile)

  # opts.args << '--devtools' # NOTE: useful for local debug
  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: opts)
end


Capybara.configure do |config|
  #config.server = :puma
  config.default_max_wait_time = 15
end

RSpec.configure do |config|

  config.raise_error_for_unimplemented_steps = true

  config.before(type: :feature) do
    Capybara.current_driver = :firefox
    page.driver.browser.manage.window.maximize
    visit(root_path)
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
      Rails.logger.warn "Taking screenshots is not implemented for \
      #{Capybara.current_driver}."
    end
  end
end

