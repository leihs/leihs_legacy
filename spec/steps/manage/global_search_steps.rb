require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

placeholder :n do
  match /\d+/, &:to_i
end

module Manage
  module Spec
    module GlobalSearchSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'a signed contract :n for a user matching :search_string exists' \
        do |n, search_string|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        instance_variable_set \
          "@contract_#{n}",
          FactoryGirl.create(:open_contract,
                             user: user,
                             inventory_pool: @current_inventory_pool)
      end

      step 'a signed contract :n for a second user matching ' \
           ':search_string exists' \
        do |n, search_string|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        instance_variable_set \
          "@contract_#{n}",
          FactoryGirl.create(:open_contract,
                             user: user,
                             inventory_pool: @current_inventory_pool)
      end

      step 'a signed contract :n for a delegation matching :search_string exists' \
        do |n, search_string|
        delegator_user = \
          FactoryGirl.create(:customer,
                             inventory_pool: @current_inventory_pool)
        delegation = FactoryGirl.create(:customer,
                                        inventory_pool: @current_inventory_pool,
                                        delegator_user: delegator_user,
                                        firstname: search_string)
        instance_variable_set \
          "@contract_#{n}",
          FactoryGirl.create(:open_contract,
                             user: delegation,
                             contact_person: delegation.delegated_users.first,
                             inventory_pool: @current_inventory_pool)
      end

      step 'a closed contract :n for a user matching :search_string ' \
           'created on :date exists' do |n, search_string, date|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        instance_variable_set \
          "@contract_#{n}",
          FactoryGirl.create(:closed_contract,
                             created_at: Date.strptime(date, '%d.%m.%Y'),
                             user: user,
                             inventory_pool: @current_inventory_pool)
      end

      step 'a closed contract :n for a contact person of a delegation ' \
           'matching :search_string created on :date exists' \
           do |n, search_string, date|
        contact_person = \
          FactoryGirl.create(:customer,
                             firstname: search_string,
                             inventory_pool: @current_inventory_pool)
        delegator_user = \
          FactoryGirl.create(:customer,
                             inventory_pool: @current_inventory_pool)
        delegation = FactoryGirl.create(:customer,
                                        inventory_pool: @current_inventory_pool,
                                        delegator_user: delegator_user,
                                        firstname: search_string)
        delegation.delegated_users << contact_person
        instance_variable_set \
          "@contract_#{n}",
          FactoryGirl.create(:closed_contract,
                             created_at: Date.strptime(date, '%d.%m.%Y'),
                             user: delegation,
                             contact_person: contact_person,
                             inventory_pool: @current_inventory_pool)
      end

      step 'I search globally for :search_string' do |search_string|
        fill_in 'search_term', with: search_string
        find('#search input').native.send_key :enter
      end

      step 'I switch to the contracts tab' do
        click_on _('Contracts')
        expect(page).to have_selector '.list-of-lines .line'
      end

      step 'within the contracts box I see contracts sorted as follows:' do |table|
        within '#contracts .list-of-lines' do
          expect(all('.row[data-id]').map { |r| r['data-id'] }).to be ==
            table.raw.flatten.map \
              { |row| instance_variable_get("@#{row.sub(' ', '_')}").id }
        end
      end

      step 'within the contracts box I see contracts sorted as follows:' do |table|
        check_contracts_within_container '#contracts .list-of-lines', table
      end

      step 'I see contracts sorted as follows:' do |table|
        check_contracts_within_container '.list-of-lines', table
      end

      step 'there is a retired item' do
        @retired_item = FactoryGirl.create(:item,
                                           retired: Date.today,
                                           retired_reason: Faker::Lorem.sentence)
      end

      step 'there is an inactive inventory pool' do
        @inactive_pool = FactoryGirl.create(:inventory_pool)
      end

      step 'the owner of the item is the inactive inventory pool' do
        @retired_item.update_attributes!(owner: @inactive_pool)
      end

      step 'the responsible of the item is the inactive inventory pool' do
        @retired_item.update_attributes!(inventory_pool: @inactive_pool)
      end

      step 'I search globally for the inventory code of the item' do
        fill_in 'search_term', with: @retired_item.inventory_code
        find('#search input').native.send_key :enter
      end

      step 'I see within the items box the item' do
        within '#items' do
          find('.line', text: @retired_item.inventory_code)
        end
      end

      step 'the item line contains the name of the inactive inventory pool' do
        within find('#items .line', text: @retired_item.inventory_code) do
          expect(current_scope).to have_content @retired_item.inventory_pool
        end
      end

      step 'the item line has the label :label' do |label|
        within find('#items .line', text: @retired_item.inventory_code) do
          expect(current_scope).to have_content _(label)
        end
      end

      step 'I wait until the contracts container is shown' do
        find('#contracts')
      end

      private

      def check_contracts_within_container(css_path, table)
        expect(find(css_path)).not_to have_selector('[data-loading]')
        within css_path do
          expect(all('.row[data-id]').map { |r| r['data-id'] }).to be ==
            table.raw.flatten.map \
            { |row| instance_variable_get("@#{row.sub(' ', '_')}").id }
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::GlobalSearchSteps,
                 manage_global_search: true
end
