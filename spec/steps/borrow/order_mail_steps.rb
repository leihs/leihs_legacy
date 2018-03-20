require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module OrderMailSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step "'deliver_received_order_notifications' is set to true " \
           'in admin settings' do
        Setting.first.update_attributes! \
          deliver_received_order_notifications: true
      end

      step 'there exists pool :letter' do |letter|
        ivar_set "@pool_#{letter}", FactoryGirl.create(:inventory_pool)
      end

      step 'there is a model :letter' do |letter|
        ivar_set "@model_#{letter}", FactoryGirl.create(:model)
      end

      step 'I have access to pool :letter' do |letter|
        FactoryGirl.create \
          :access_right,
          user: @customer,
          inventory_pool: ivar_get("@pool_#{letter}"),
          role: :customer
      end

      step 'pool :pool_letter has a borrowable item for model :model_letter' \
        do |pool_letter, model_letter|
        FactoryGirl.create(:item,
                           model: ivar_get("@model_#{model_letter}"),
                           is_borrowable: true,
                           owner: ivar_get("@pool_#{pool_letter}"),
                           inventory_pool: ivar_get("@pool_#{pool_letter}"))
      end

      step 'the customer has an unsubmitted reservation for model :model_letter ' \
           'and pool :pool_letter' do |model_letter, pool_letter|
        FactoryGirl.create(:reservation,
                           status: :unsubmitted,
                           user: @customer,
                           inventory_pool: ivar_get("@pool_#{pool_letter}"),
                           model: ivar_get("@model_#{model_letter}"))
      end

      step 'I open the current order page' do
        visit borrow_current_order_path
      end

      step 'I fill in the purpose' do
        fill_in 'purpose', with: Faker::Lorem.sentence
      end

      step 'I click on submit' do
        click_button _('Submit Order')
      end

      step '4 mails has been sent' do
        expect(ActionMailer::Base.deliveries.count).to be == 4
      end

      step 'one mail with received template was sent to pool :letter' do |letter|
        m = ActionMailer::Base.deliveries.find do |mail|
          mail.to.first == ivar_get("@pool_#{letter}").email and
            mail.subject.match(/received/i)
        end
        expect(m).to be
      end

      step 'one mail with submitted template for pool :letter ' \
           'was sent to the customer' do |letter|
        m = ActionMailer::Base.deliveries.find do |mail|
          mail.to.first == @customer.email and
            mail.subject.match(/submitted/i) and
            mail.body.match(/#{ivar_get("@pool_#{letter}").name}/)
        end
        expect(m).to be
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::OrderMailSteps, borrow_order_mails: true
end
