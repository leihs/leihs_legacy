require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module SerialNumberValidationSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is an item with serial number :serial_number' do |serial_number|
        FactoryGirl.create(:item,
                           owner_id: @current_inventory_pool.id,
                           serial_number: serial_number)
      end

      step 'I open the page for creating a new item' do
        visit manage_new_item_path(@current_inventory_pool)
      end

      step 'I enter an inventory code' do
        fill_in 'item[inventory_code]', with: Faker::Lorem.characters(6)
      end

      step 'I select a model' do
        model = @current_inventory_pool.models.first
        type_into_and_select_from_autocomplete(
          "[data-autocomplete_value_target='item[model_id]']",
          model.name
        )
      end

      step 'I select a supply category' do
        select 'AV Technology', from: 'item[properties][anschaffungskategorie]'
      end

      step 'I enter serial number :serial_number' do |serial_number|
        @serial_number = serial_number
        fill_in 'item[serial_number]', with: serial_number
      end

      step 'I see a confirmation dialog that there already exists same ' \
           'or similar serial number' do
        expect(page.driver.browser.switch_to.alert.text)
          .to match /serial number already exists/
      end

      step 'I stay on the create item page' do
        expect(current_path).to be == manage_new_item_path(@current_inventory_pool)
      end

      step 'I stay on the edit item page' do
        expect(current_path)
          .to be == manage_edit_item_path(@current_inventory_pool, @item)
      end

      step 'the loading icon was hidden' do
        expect(page).not_to have_selector "img[src*='loading.gif']"
      end

      step 'the new item was created' do
        expect(Item.find_by_serial_number(@serial_number)).to be
      end

      step 'the new item was not created' do
        expect(Item.find_by_serial_number(@serial_number)).not_to be
      end

      step 'I was redirected to the inventory page' do
        find('#inventory')
        expect(current_path)
          .to be == manage_inventory_path(@current_inventory_pool)
      end

      step 'there is another item in the current inventory pool' do
        @item = FactoryGirl.create(:item,
                                   owner_id: @current_inventory_pool.id)
      end

      step 'I open the page for editing an item' do
        visit manage_edit_item_path(@current_inventory_pool, @item)
      end

      step 'the item was not updated' do
        expect(Item.find_by_serial_number(@serial_number)).not_to be
      end

      step 'the item was updated' do
        expect(Item.find_by_serial_number(@serial_number)).to be
      end

      step 'I choose a building' do
        type_into_and_select_from_autocomplete \
          "[data-autocomplete_value_target='item[room][building_id]'",
          Building.general.name
      end

      step 'I choose a room' do
        type_into_and_select_from_autocomplete \
          "[data-autocomplete_value_target='item[room_id]'",
          Building.general.rooms.find_by_general(true).name
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::SerialNumberValidationSteps,
                 manage_serial_number_validation: true
end
