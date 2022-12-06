require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module InactiveInventoryPoolSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there exists an inactive inventory pool ' \
           'I have access to as :role' do |role|
        @inactive_inventory_pool = \
          FactoryBot.create(:inventory_pool, is_active: false)
        FactoryBot.create(:access_right,
                           user: @current_user,
                           inventory_pool: @inactive_inventory_pool,
                           role: role.sub(' ', '_'))
      end

      step 'I hover over the current inventory pool in navigation bar' do
        el = find('#topbar .topbar-item', text: @current_inventory_pool.name)
        el.hover
      end

      step "I don't see the inactive inventory pool in the list" do
        within '#topbar .dropdown' do
          expect(page).not_to have_content @inactive_inventory_pool.name
        end
      end

      step 'there is an item which is owned by the current inventory pool' do
        @item = FactoryBot.create(:item, owner: @current_inventory_pool)
      end

      step 'there exists an inactive inventory pool' do
        @inactive_inventory_pool = FactoryBot.create(:inventory_pool,
                                                      is_active: false)
      end

      step 'open the edit page for the item' do
        visit manage_edit_item_path(@current_inventory_pool, @item)
      end

      step 'I fill in the name of the inactive inventory pool ' \
           'for "Responsible department"' do
        within find('#inventory_pool_id input') do
          current_scope.set ""
          current_scope.set @inactive_inventory_pool.name
        end
      end

      step 'there is no autocomplete menu visible' do
        expect(page).not_to have_selector '.ui-autocomplete'
      end

      step "there is the pool in the dropdown with the suffix 'inactive'" do
        within '.ui-autocomplete' do
          expect(current_scope).to have_content \
            "#{@inactive_inventory_pool.name} (#{_('inactive')})"
        end
      end

      step 'there is a retired item which is owned by the the current pool ' \
           'but in responsibility of the inactive inventory pool' do
        @item = FactoryBot.create(:item,
                                   retired: Date.today,
                                   retired_reason: Faker::Lorem.sentence,
                                   inventory_pool: @inactive_inventory_pool,
                                   owner: @current_inventory_pool)
      end

      step 'I open the inventory list' do
        visit manage_inventory_path(@current_inventory_pool)
      end

      step 'I enter the inventory code of the item ' \
           'in the inventory search field' do
        find('#list-search').set @item.inventory_code
      end

      step 'no item is found' do
        within '#inventory' do
          expect(page).to have_content _('No entries found')
        end
      end

      step 'I there is not possibility to choose the inactive inventory pool ' \
           'from the inventory pools select field' do
        within "select[name='responsible_inventory_pool_id']" do
          expect(page).not_to have_content @inactive_inventory_pool.name
        end
      end

      step 'open the inventory helper page' do
        visit manage_inventory_helper_path(@current_inventory_pool)
      end

      step 'choose the responsible department via field select box' do
        type_into_and_select_from_autocomplete(
          '#field-input', _('Responsible department')
        )
      end

      step 'I fill in the name of the inactive inventory pool ' \
           'in the responsible department field' do
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::InactiveInventoryPoolSteps,
                 manage_inactive_inventory_pools: true
end
