require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module InventoryPoolSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      # def user_by_login(login)
      #   User.find_by(login: login)
      # end

      step 'there is a pool :letter with borrowable items ' \
           'the user has access to' do |letter|
        instance_variable_set("@pool_#{letter}",
                              FactoryGirl.create(:inventory_pool))
        FactoryGirl.create(
          :access_right,
          user: @user,
          inventory_pool: instance_variable_get("@pool_#{letter}"),
          role: :customer
        )
        FactoryGirl.create(
          :item,
          inventory_pool: instance_variable_get("@pool_#{letter}"),
          is_borrowable: true
        )
      end

      step 'there is a pool :letter without borrowable items ' \
           'the user has access to' do |letter|
        instance_variable_set("@pool_#{letter}",
                              FactoryGirl.create(:inventory_pool))
        FactoryGirl.create(
          :access_right,
          user: @user,
          inventory_pool: instance_variable_get("@pool_#{letter}"),
          role: :customer
        )
      end

      step 'there is a pool :letter the user has access to but ' \
           'the user is suspended for' do |letter|
        instance_variable_set("@pool_#{letter}",
                              FactoryGirl.create(:inventory_pool))
        FactoryGirl.create(
          :access_right,
          user: @user,
          inventory_pool: instance_variable_get("@pool_#{letter}"),
          suspended_until: Date.tomorrow,
          suspended_reason: Faker::Lorem.sentence,
          role: :customer
        )
      end

      step 'there is a pool :letter the user had access to in the past' do |letter|
        instance_variable_set("@pool_#{letter}",
                              FactoryGirl.create(:inventory_pool))
        ar = FactoryGirl.create(
          :access_right,
          user: @user,
          inventory_pool: instance_variable_get("@pool_#{letter}"),
          role: :customer
        )

        ar.destroy
      end

      step 'I visit the page of my inventory pools' do
        click_on _('Inventory Pools')
      end

      step 'I see 3 pools' do
        expect(all('[data-id]').count).to be == 3
      end

      step 'I see pool :letter' do |letter|
        pool = instance_variable_get("@pool_#{letter}")
        within "[data-id='#{pool.id}']" do
          expect(current_scope).to have_content pool.name
        end
      end

      step 'I see pool :letter with a label :label' do |letter, label|
        pool = instance_variable_get("@pool_#{letter}")
        within "[data-id='#{pool.id}']" do
          expect(current_scope)
            .to have_content instance_variable_get("@pool_#{letter}").name
          expect(current_scope)
            .to have_content _(label)
        end
      end

    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::InventoryPoolSteps, borrow_inventory_pools: true
end
