require 'pry'
require 'rubygems'
require 'fileutils'

require 'cucumber/rails' # likely needs to stay, even if split from rails setup

port = ENV['LEIHS_LEGACY_HTTP_PORT'] || 3333
Capybara.server_host = '0.0.0.0'
Capybara.server_port = port
Capybara.app_host = "http://host.docker.internal:#{port}"

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

Capybara.default_selector = :css

require 'selenium/webdriver'

SELENIUM_START_WAIT_SECONDS = 120

Capybara.register_driver :firefox do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox
  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 240 # seconds

  selenium_url = ENV['SELENIUM_URL'] || 'http://localhost:4444'

  Capybara::Selenium::Driver.new(app,
    browser: :remote,
    url: "#{selenium_url}/wd/hub", # e.g.  'http://localhost:4444/wd/hub'
    capabilities: capabilities,
    http_client: http_client)
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
