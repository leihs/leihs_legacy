require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Spec
  module TimeZoneSteps
    include ::Spec::CommonSteps
    include ::Spec::LoginSteps
    include ::Spec::PersonasDumpSteps

    step 'the time zone is set to :time_zone' do |time_zone|
      ApplicationRecord.connection.execute <<-SQL
        UPDATE settings SET time_zone = '#{time_zone}'
      SQL
    end

    step 'I open the create model page' do
      visit manage_new_model_path(@current_inventory_pool)
    end

    step 'I see a notice message' do
      find('#flash .notice')
    end

    step 'I fill in the model name' do
      @name = Faker::Lorem.words(3).join(' ')
      find('#product').find('input').set @name
    end

    step 'the model was created in the database' do
      @model = Model.find_by_name(@name)
      expect(@model).to be
    end

    step "the model's created_at attribute has time zone :time_zone" do |time_zone|
      expect(@model.created_at.time_zone.name).to be == time_zone
    end
  end
end

RSpec.configure do |config|
  config.include Spec::TimeZoneSteps, time_zone: true
end
