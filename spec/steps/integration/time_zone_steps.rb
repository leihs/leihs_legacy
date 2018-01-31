require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Spec
  module TimeZoneSteps
    include ::Spec::CommonSteps
    include ::Spec::LoginSteps
    include ::Spec::PersonasDumpSteps

    step 'I open the settings page' do
      visit admin.settings_path
    end

    step 'I set time zone to :time_zone' do |time_zone|
      find('#setting_time_zone').select(time_zone)
    end

    step 'the time zone is now set to :time_zone' do |time_zone|
      expect(find('#setting_time_zone').value).to be == time_zone
    end

    step 'I click on "Save Settings"' do
      page.execute_script 'window.scrollBy(0,-10000)'
      click_on _('Save Settings')
    end

    step 'I open the create model page' do
      visit manage_new_model_path(@current_inventory_pool)
    end

    step 'I see a notice message' do
      find('#flash .notice')
    end

    step 'I fill in the model name' do
      @name = Faker::Lorem.words(3).join(' ')
      find("[name='model[product]']").set @name
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
