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

      step 'I have an unsubmitted reservation for this pool ' \
           'and the model of this item' do
        FactoryGirl.create(:reservation,
                           user: @customer,
                           inventory_pool: @inventory_pool,
                           status: :unsubmitted,
                           model: @item.model)
      end

      step 'I have an unsubmitted reservation for this pool ' \
           'with reservation time of :n days' do |n|
        @reservation =
          FactoryGirl.create(:reservation,
                             user: @customer,
                             inventory_pool: @inventory_pool,
                             status: :unsubmitted,
                             start_date: Date.today,
                             end_date: Date.today + (n.to_i - 1))
      end

      step 'the pool is open on the start and end date of the reservation' do
        wd = @reservation.inventory_pool.workday
        d1 = Workday::WORKDAYS[@reservation.start_date.wday]
        d2 = Workday::WORKDAYS[@reservation.end_date.wday]
        wd.update_attributes! d1 => true, d2 => true
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
        expect(find('#flash .error').text).to match /User is suspended/
      end

      step 'I see an error message in respect to the maximum reservation time' do
        expect(find('#flash .error').text).to match /Maximum reservation time/
      end

      step 'the order was not submitted' do
        expect(@current_user.orders.submitted).to be_empty
      end

      step 'the order was submitted successfully' do
        expect(@current_user.orders.submitted.count).to eq 1
      end

      step 'the reservation advance days for this pool is set to :n' do |n|
        @inventory_pool.workday.update_attributes!(
          reservation_advance_days: n.to_i
        )
      end

      step 'I have an unsubmitted reservation for this pool starting yesterday' do
        FactoryGirl.create(:reservation,
                           user: @customer,
                           inventory_pool: @inventory_pool,
                           status: :unsubmitted,
                           start_date: Date.yesterday)
      end

      step 'I am redirected to the timeout page' do
        expect(current_path).to eq borrow_refresh_timeout_path
      end

      step 'I see an error message in respect to the reservation advance days' do
        within find('#flash .error') do
          expect(current_scope).to have_content \
            'minimal reservation advance period'
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::SubmitOrderSteps, borrow_submit_order: true
end
