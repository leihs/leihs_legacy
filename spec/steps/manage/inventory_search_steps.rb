require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module InventorySearchSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is an item the current pool is owner of ' \
           'situated in room :room' do |room|
        FactoryGirl.create(:item,
                           owner: @current_inventory_pool,
                           room: FactoryGirl.create(:room,
                                                    name: room))
      end

      step 'I open the inventory list page' do
        visit manage_inventory_path(@current_inventory_pool)
      end

      step 'I search after :search_string' do |search_string|
        fill_in 'list-search', with: search_string
      end

      step 'I see one model line corresponding to the item ' \
           'situated in :room' do |room|
        items = Item.joins(:room).where(rooms: { name: room })
        expect(items.count).to be == 1
        item = Item.joins(:room).where(rooms: { name: room }).first
        within '#inventory' do
          find("[data-type='model']")
          expect(all("[data-type='model']").count).to be == 1
          expect(all("[data-type='model']").first.text).to match item.model.name
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::InventorySearchSteps,
                 manage_inventory_search: true
end
