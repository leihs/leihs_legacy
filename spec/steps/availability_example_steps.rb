require_relative 'shared/common_steps'
require_relative 'shared/login_steps'
require_relative 'shared/personas_dump_steps'

module Spec
  module AvailabilityExampleSteps
    include ::Spec::CommonSteps
    include ::Spec::LoginSteps
    include ::Spec::PersonasDumpSteps

    DIR_PATH = \
      '../documentation/sources/business_logic/availability_example'.freeze

    step 'basic data file is loaded' do
      load "#{DIR_PATH}/basic_data.rb"
    end

    step 'soft overbooking file is loaded' do
      load "#{DIR_PATH}/soft_overbooking.rb"
    end

    step 'hard overbooking file is loaded' do
      load "#{DIR_PATH}/hard_overbooking.rb"
    end

    step 'eval :code' do |code|
      eval code
    end

    step 'I visit the old timeline for the model' do
      path = ['/manage/',
              Example.instance_eval { @pool.id },
              '/models/',
              Example.instance_eval { @model.id },
              '/old_timeline'].join
      visit path
    end
  end
end

RSpec.configure do |config|
  config.include Spec::AvailabilityExampleSteps, availability_example: true
end
