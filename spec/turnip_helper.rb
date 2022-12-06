require 'active_support/all'
require 'capybara/rspec'
require 'config/database.rb'
require 'factory_bot'
require 'pry'
require 'rails_helper'
require 'selenium-webdriver'
require 'turnip/capybara'
require 'turnip/rspec'

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

# DOCS:
# * https://www.rubydoc.info/github/jnicklas/capybara#configuring-and-adding-drivers
# * https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings
# * https://github.com/SeleniumHQ/docker-selenium

SELENIUM_START_WAIT_SECONDS = 120

Capybara.register_driver :firefox do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox
  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 240 # seconds

  selenium_url = ENV['SELENIUM_URL'] || 'http://localhost:4444'

  Capybara::Selenium::Driver.new(app,
    browser: :remote,
    url: "#{selenium_url}/wd/hub",
    capabilities: capabilities,
    http_client: http_client)
end

port = ENV['LEIHS_LEGACY_HTTP_PORT'] || 3333
Capybara.server_host = '0.0.0.0'
Capybara.server_port = port
Capybara.app_host = "http://host.docker.internal:#{port}"

RSpec.configure do |config|

  config.raise_error_for_unimplemented_steps = true

  config.before(type: :feature) do
    PgTasks.truncate_tables()
    Config::Database.restore_seeds
    Capybara.current_driver = :firefox
    # binding.pry
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
      Rails
        .logger
        .warn "Taking screenshots is not implemented for \
      #{Capybara.current_driver}."
    end
  end
end

# def wait_for_selenium_connection
#   url = URI.parse(ENV['SELENIUM_URL'])
#   begin
#     Timeout.timeout(SELENIUM_START_WAIT_SECONDS) do
#       print "INFO: waiting for connection to Selenium at '#{url}'... "
#       until
#         # TODO: look at the answer if server is ready, see: https://github.com/SeleniumHQ/docker-selenium#using-a-bash-script-to-wait-for-the-grid
#         begin; Net::HTTP.start(url.host, url.port, read_timeout: 1) { true }; rescue; end
#       sleep 1
#       end
#     end
#   rescue Timeout::Error => err
#     puts; puts "ERROR: could not connect to Selenium at '#{url}'"
#     throw err
#   end
#   puts 'OK!'
# end
