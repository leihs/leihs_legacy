require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module ModelTransportableSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I open the create model page' do
        visit manage_new_model_path(@current_inventory_pool)
      end

      step 'I open the create software page' do
        visit manage_new_model_path(@current_inventory_pool, type: 'software')
      end

      step 'I open the edit page of the model' do
        visit manage_edit_model_path(@current_inventory_pool, @model)
      end

      step 'I open the edit page of the created model' do
        visit manage_edit_model_path(@current_inventory_pool, @model)
      end

      step 'there is a package model' do
        @model = FactoryBot.create(:package_model)
      end

      step 'I mark the model as a package' do
        checkbox = find('#is_package input[type=checkbox]')
        checkbox.click unless checkbox.checked?
      end

      step 'the current pool has a pickup location' do
        FactoryBot.create(:pickup_location, inventory_pool: @current_inventory_pool)
      end

      step 'the current pool has alternative pickup locations enabled' do
        @current_inventory_pool.update!(enable_alternative_pickup_locations: true)
      end

      step 'the transportable checkbox is not visible' do
        expect(page).not_to have_selector('#transportable')
      end

      step 'the transportable checkbox is visible' do
        find('#transportable')
      end

      step 'the transportable checkbox is checked' do
        expect(find('#transportable input[type=checkbox]')).to be_checked
      end

      step 'the transportable checkbox is not checked' do
        expect(find('#transportable input[type=checkbox]')).not_to be_checked
      end

      step 'the transportable checkbox is enabled' do
        expect(find('#transportable input[type=checkbox]')).not_to be_disabled
      end

      step 'I uncheck the transportable checkbox' do
        checkbox = find('#transportable input[type=checkbox]')
        checkbox.click if checkbox.checked?
      end

      step 'I check the transportable checkbox' do
        checkbox = find('#transportable input[type=checkbox]')
        checkbox.click unless checkbox.checked?
      end

      step 'I fill in the product name' do
        @product_name = "Transportable Test Model #{SecureRandom.hex(4)}"
        find('#product input').set @product_name
      end

      step 'the model has been saved successfully' do
        step 'I see a success message'
      end

      step 'the created model is not transportable' do
        @model = Model.find_by!(product: @product_name)
        expect(@model.transportable).to eq(false)
      end

      step 'the created model is transportable' do
        expect(@model.reload.transportable).to eq(true)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::ModelTransportableSteps,
                 manage_model_transportable: true
end
