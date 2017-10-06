require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module SubmitOrderSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I am suspended for a pool I am a customer of' do
        ar = AccessRight.find_by(inventory_pool: @inventory_pool, role: :customer)
        ar.update_attributes(suspended_until: Date.tomorrow,
                             suspended_reason: Faker::Lorem.sentence)
      end

      step 'there is a borrowable item in this pool' do
        @item = FactoryGirl.create(:item, owner: @inventory_pool)
      end

      step 'I have an unsubmitted order for this pool ' \
           'and the model of this item' do
        FactoryGirl.create(:reservation,
                           user: @customer,
                           inventory_pool: @inventory_pool,
                           status: :unsubmitted,
                           model: @item.model)
      end

      step 'I open the page for this order' do
        visit borrow_order_path
      end

      step 'I enter the purpose of my order' do
        fill_in 'purpose', with: Faker::Lorem.sentence
      end

      step 'I submit' do
        click_button _('Submit Order')
      end

      step 'I see an error message in respect of my suspension' do
        expect(find('#flash .error').text).to match /This user is suspended/
      end

      step 'the order was not submitted' do
        expect(@current_user.orders.submitted).to be_empty
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::SubmitOrderSteps, borrow_submit_order: true
end
