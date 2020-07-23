require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module InactiveInventoryPoolsSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I have an access as customer to this inventory pool' do
        FactoryGirl.create(:access_right,
                           user: @current_user,
                           inventory_pool: @inventory_pool)
      end

      step 'this inventory pool has a borrowable item' do
        FactoryGirl.create(:item,
                           owner: @inventory_pool,
                           is_borrowable: true)
      end

      step 'the active inventory pool has a borrowable item' do
        @item_from_active = \
          FactoryGirl.create(:item,
                             owner: @active_inventory_pool,
                             is_borrowable: true)
      end

      step 'the model of the item from the active pool belongs to the category' do
        @category.models << @item_from_active.model
      end

      step 'the model of the item from the inactive pool ' \
           'belongs to the category' do
        @category.models << @item_from_inactive.model
      end

      step 'the inactive inventory pool has a borrowable and retired item' do
        @item_from_inactive = \
          FactoryGirl.create(:item,
                             owner: @inactive_inventory_pool,
                             retired: Date.today,
                             retired_reason: Faker::Lorem.sentence,
                             is_borrowable: true)
      end

      step 'I have an access as customer to the active inventory pool' do
        FactoryGirl.create(:access_right,
                           user: @current_user,
                           inventory_pool: @active_inventory_pool)
      end

      step 'I have an access as customer to the inactive inventory pool' do
        FactoryGirl.create(:access_right,
                           user: @current_user,
                           inventory_pool: @inactive_inventory_pool)
      end

      step 'I open inventory pools page' do
        visit borrow_inventory_pools_path
      end

      step 'I don\'t see the inactive inventory pool' do
        expect(page).not_to have_content @inactive_inventory_pool.name
      end

      step 'I open the model list for the category' do
        visit borrow_models_path(category_id: @category.id)
      end

      step 'I see the model from the active inventory pool' do
        within '#model-list' do
          expect(page).to have_content @item_from_active.model.name
        end
      end

      step 'I don\'t see the model from the inactive inventory pool' do
        within '#model-list' do
          expect(page).not_to have_content @item_from_inactive.model.name
        end
      end

      step 'I open the booking calendar for the model ' \
           'from the active inventory pool' do
        find(".row[data-id='#{@item_from_active.model.id}']")
          .find('[data-create-order-line]')
          .click
      end

      step 'the inactive inventory pool is not displayed ' \
           'in the pool selection dropdown of the filter' do
        within '#ip-selector' do
          expect(page).not_to have_content @inactive_inventory_pool.name
        end
      end

      step 'the inactive inventory pool is not displayed ' \
           'in the pool selection dropdown' do
        within '#booking-calendar-inventory-pool' do
          expect(page).not_to have_content @inactive_inventory_pool.name
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::InactiveInventoryPoolsSteps,
                 borrow_inactive_inventory_pools: true
end
