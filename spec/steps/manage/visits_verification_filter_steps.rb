require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module VisitsVerificationFilterSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is an inventory pool' do
        @inventory_pool = FactoryGirl.create(:inventory_pool)
      end

      step 'there is a lending manager in this inventory pool' do
        @lending_manager = FactoryGirl.create(:lending_manager,
                                              inventory_pool: @inventory_pool)
      end

      step 'I am logged in as the lending manager' do
        I18n.locale = @lending_manager.language.locale
        visit root_path
        fill_in :email, with: @lending_manager.email
        click_on _('Login')
      end

      step 'there is an entitlement group with required verification' do
        @entitlement_group = \
          FactoryGirl.create(:group, is_verification_required: true)
        @inventory_pool.entitlement_groups << @entitlement_group
      end

      step 'there is a model with items in the group' do
        @model = FactoryGirl.create(:model_with_items)
      end

      step 'there is a hand over :n without required verification' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        date = Date.today + n.to_i.day

        FactoryGirl.create(
          :reservation,
          inventory_pool: @inventory_pool,
          status: :approved,
          user: user,
          model: FactoryGirl.create(:model_with_items),
          start_date: date,
          end_date: date + 1.day
        )

        instance_variable_set(
          "@hand_over_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'hand_over',
            date: date
          )
        )
      end

      step 'there is a hand over :n with user to verify' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        @entitlement_group.users << user
        date = Date.today + n.to_i.day

        FactoryGirl.create(
          :reservation,
          inventory_pool: @inventory_pool,
          status: :approved,
          user: user,
          model: FactoryGirl.create(:model_with_items),
          start_date: date,
          end_date: date + 1.day
        )

        instance_variable_set(
          "@hand_over_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'hand_over',
            date: date
          )
        )
      end

      step 'there is a hand over :n with user and model to verify' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        model = FactoryGirl.create(:model_with_items)
        @entitlement_group.users << user
        @entitlement_group.entitlements << \
          FactoryGirl.create(:entitlement,
                             model: model,
                             quantity: 1)
        date = Date.today + n.to_i.day

        FactoryGirl.create(
          :reservation,
          inventory_pool: @inventory_pool,
          status: :approved,
          user: user,
          model: model,
          start_date: date,
          end_date: date + 1.day
        )

        instance_variable_set(
          "@hand_over_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'hand_over',
            date: date
          )
        )
      end

      step 'there is a take back :n without required verification' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        date = Date.today + n.to_i.day
        model = FactoryGirl.create(:model_with_items)

        ApplicationRecord.transaction do
          contract = FactoryGirl.build(:contract,
                                       user: user,
                                       state: :open,
                                       inventory_pool: @inventory_pool)
          contract.reservations << \
            FactoryGirl.build(
              :reservation,
              inventory_pool: @inventory_pool,
              status: :signed,
              user: user,
              model: model,
              item: model.items.first,
              contract: contract,
              start_date: date - 1.day,
              end_date: date
            )
          contract.save!
        end

        instance_variable_set(
          "@take_back_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'take_back',
            date: date
          )
        )
      end

      step 'there is a take back :n with user to verify' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        model = FactoryGirl.create(:model_with_items)
        @entitlement_group.users << user
        date = Date.today + n.to_i.day

        ApplicationRecord.transaction do
          contract = FactoryGirl.build(:contract,
                                       user: user,
                                       state: :open,
                                       inventory_pool: @inventory_pool)
          contract.reservations << \
            FactoryGirl.build(
              :reservation,
              inventory_pool: @inventory_pool,
              status: :signed,
              user: user,
              model: model,
              item: model.items.first,
              contract: contract,
              start_date: date - 1.day,
              end_date: date
            )
          contract.save!
        end

        instance_variable_set(
          "@take_back_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'take_back',
            date: date
          )
        )
      end

      step 'there is a take back :n with user and model to verify' do |n|
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @inventory_pool)
        model = FactoryGirl.create(:model_with_items)
        @entitlement_group.users << user
        @entitlement_group.entitlements << \
          FactoryGirl.create(:entitlement,
                             model: model,
                             quantity: 1)
        date = Date.today + n.to_i.day

        ApplicationRecord.transaction do
          contract = FactoryGirl.build(:contract,
                                       user: user,
                                       state: :open,
                                       inventory_pool: @inventory_pool)
          contract.reservations << \
            FactoryGirl.build(
              :reservation,
              inventory_pool: @inventory_pool,
              status: :signed,
              user: user,
              model: model,
              item: model.items.first,
              contract: contract,
              start_date: date - 1.day,
              end_date: date
            )
          contract.save!
        end

        instance_variable_set(
          "@take_back_#{n}",
          Visit.find_by(
            user: user,
            inventory_pool: @inventory_pool,
            type: 'take_back',
            date: date
          )
        )
      end

      step 'I open the visits page' do
        visit manage_inventory_pool_visits_path(@inventory_pool)
      end

      step 'I click on hand over tab' do
        within '#list-tabs' do
          find('a', text: _('Hand Over')).click
        end
      end

      step 'I click on take back tab' do
        within '#list-tabs' do
          find('a', text: _('Take Back')).click
        end
      end

      step 'I see :n visits' do |n|
        within '#visits' do
          unless n.to_i.zero?
            find('[data-id]', match: :first)
          end
          expect(all('[data-id]').count).to be == n.to_i
        end
      end

      step 'I choose :option from the select field' do |option|
        select _(option), from: :verification
      end

      step 'I see hand over :n' do |n|
        hand_over = instance_variable_get("@hand_over_#{n}")
        within '#visits' do
          find("[data-id='#{hand_over.id}']")
        end
      end

      step 'I see take back :n' do |n|
        take_back = instance_variable_get("@take_back_#{n}")
        within '#visits' do
          find("[data-id='#{take_back.id}']")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::VisitsVerificationFilterSteps,
                 manage_visits_verification_filter: true
end
