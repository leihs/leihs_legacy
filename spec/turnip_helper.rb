require 'turnip/capybara'
require 'turnip/rspec'
require 'config/browser.rb'

Dir[File.expand_path('steps/**/*_steps.rb', __dir__)].sort.each do |steps_file|
  require steps_file
end
