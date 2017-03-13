require 'rails_helper'
require 'factory_girl'

Dir.glob("#{__dir__}/steps/**/*.rb") { |f| require f }
Dir.glob("#{__dir__}/factories/**/*factory.rb") { |f| require f }
load "#{__dir__}/../lib/procurement/file_utilities.rb"
