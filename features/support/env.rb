require 'rubygems'
require 'fileutils'


require 'cucumber/rails'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

Capybara.default_selector = :css

##################################################################################

Capybara.configure do |config|
  config.server = :puma
  config.default_max_wait_time = 15
end

##################################################################################

require 'selenium/webdriver'


Capybara.register_driver :firefox do |app|
  firefox_bin_path = if ENV["TOOL_VERSIONS_MANAGER"] == "mise"
    Pathname.new(`mise where firefox`.strip).join("bin/firefox").expand_path.to_s
  else
    Pathname.new(`asdf where firefox`.strip).join("bin/firefox").expand_path.to_s
  end
  Selenium::WebDriver::Firefox.path = firefox_bin_path
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox

  profile = Selenium::WebDriver::Firefox::Profile.new
  opts = Selenium::WebDriver::Firefox::Options.new(
    binary: firefox_bin_path,
    profile: profile)


  # opts.args << '--devtools' # NOTE: useful for local debug
  Capybara::Selenium::Driver.new(
    app,
    capabilities: capabilities,
    browser: :firefox,
    options: opts)
end

##################################################################################

Before('not @rack') do
  Capybara.default_driver = :firefox
  Capybara.current_driver = :firefox
  page.driver.browser.manage.window.maximize
end

Before do
  Cucumber.logger.info "Current capybara driver: %s\n" % Capybara.current_driver
  Dataset.restore_dump
  puts(root_path)
  visit(root_path)
end

module Capybara::Node::Finders
  # override due to raising an error instead of returning nil
  def first(*args, **options, &optional_filter_block)
    options = { minimum: 0 }.merge(options) unless options_include_minimum?(options)
    all(*args, **options, &optional_filter_block).first
  end
end
