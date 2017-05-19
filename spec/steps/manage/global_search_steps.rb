require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module GlobalSearchSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'a signed contract for a user matching :search_string exists' \
        do |search_string|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        @contract_1 = FactoryGirl.create(:signed_contract,
                                         user: user,
                                         inventory_pool: @current_inventory_pool)
      end

      step 'a signed contract for a second user matching :search_string exists' \
        do |search_string|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        @contract_2 = FactoryGirl.create(:signed_contract,
                                         user: user,
                                         inventory_pool: @current_inventory_pool)
      end

      step 'a closed contract for a user matching :search_string exists' \
        do |search_string|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool,
                                  firstname: search_string)
        @contract_3 = FactoryGirl.create(:closed_contract,
                                         user: user,
                                         inventory_pool: @current_inventory_pool)
      end

      step 'a signed contract for a delegation matching :search_string exists' \
        do |search_string|
        delegator_user = \
          FactoryGirl.create(:customer,
                             inventory_pool: @current_inventory_pool)
        delegation = FactoryGirl.create(:customer,
                                        inventory_pool: @current_inventory_pool,
                                        delegator_user: delegator_user,
                                        firstname: search_string)
        @contract_4 = FactoryGirl.create(:signed_contract,
                                         user: delegation,
                                         inventory_pool: @current_inventory_pool)
      end

      step 'a closed contract for a contact person of a delegation ' \
           'matching :search_string exists' do |search_string|
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
        @contract_5 = FactoryGirl.create(:closed_contract,
                                         user: delegation,
                                         contact_person: contact_person,
                                         inventory_pool: @current_inventory_pool)
      end

      step 'a closed contract for a second delegation ' \
           'matching :search_string exists' do |search_string|
        delegator_user = \
          FactoryGirl.create(:customer,
                             inventory_pool: @current_inventory_pool)
        delegation = FactoryGirl.create(:customer,
                                        inventory_pool: @current_inventory_pool,
                                        delegator_user: delegator_user,
                                        firstname: search_string)
        @contract_6 = FactoryGirl.create(:closed_contract,
                                         user: delegation,
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

      step 'within the contracts box on the 1st position I see ' \
           'the signed contract for the user' do
        within '#contracts .list-of-lines' do
          expect(all('.line[data-id]')[0]['data-id']).to be == @contract_1.id
        end
      end

      step 'within the contracts box on the 2nd position I see ' \
           'the signed contract for the second user' do
        within '#contracts .list-of-lines' do
          expect(all('.line[data-id]')[1]['data-id']).to be == @contract_2.id
        end
      end

      step 'within the contracts box on the 3rd position I see ' \
           'the closed contract for the user' do
        within '#contracts .list-of-lines' do
          expect(all('.line[data-id]')[2]['data-id']).to be == @contract_3.id
        end
      end

      step 'within the contracts box on the 4th position I see ' \
           'the signed contract for the delegation' do
        within '#contracts .list-of-lines' do
          expect(all('.line[data-id]')[3]['data-id']).to be == @contract_4.id
        end
      end

      step 'within the contracts box on the 5th position I see ' \
           'the closed contract for the contact person of a delegation' do
        within '#contracts .list-of-lines' do
          expect(all('.line[data-id]')[4]['data-id']).to be == @contract_5.id
        end
      end

      step 'on the 1st position I see ' \
           'the signed contract for the user' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[0]['data-id']).to be == @contract_1.id
        end
      end

      step 'on the 2nd position I see ' \
           'the signed contract for the second user' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[1]['data-id']).to be == @contract_2.id
        end
      end

      step 'on the 3rd position I see ' \
           'the closed contract for the user' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[2]['data-id']).to be == @contract_3.id
        end
      end

      step 'on the 4th position I see ' \
           'the signed contract for the delegation' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[3]['data-id']).to be == @contract_4.id
        end
      end

      step 'on the 5th position I see ' \
           'the closed contract for the contact person of a delegation' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[4]['data-id']).to be == @contract_5.id
        end
      end

      step 'on the 6th position I see ' \
           'the closed contract for the second delegation' do
        within '.list-of-lines' do
          expect(all('.line[data-id]')[5]['data-id']).to be == @contract_6.id
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::GlobalSearchSteps,
                 manage_global_search: true
end
