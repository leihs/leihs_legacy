require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module BookingCalendarSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I open the model page' do
        visit borrow_model_path(@model)
      end

      step 'there is a borrowable item for the model and the inventory pool' do
        FactoryGirl.create(:item,
                           is_borrowable: true,
                           model: @model,
                           owner: @inventory_pool,
                           inventory_pool: @inventory_pool)
      end

      step 'I am customer of the pool' do
        FactoryGirl.create(:access_right,
                           user: @current_user,
                           inventory_pool: @inventory_pool)
      end

      step 'I set the start date to today' do
        sd = Date.today.strftime('%d/%m/%Y')
        find('#booking-calendar-start-date').set sd
      end

      step 'I set the end date to today + :n days' do |n|
        ed = (Date.today + n.to_i.days).strftime('%d/%m/%Y')
        find('#booking-calendar-end-date').set ed
      end

      step 'within the booking calendar I see an error message ' \
           'in regards to the maximum reservation time' do
        within '.modal #booking-calendar-errors' do
          expect(current_scope).to have_content /maximum reservation time/i
        end
      end

      step 'the reservation has not been created' do
        expect(@current_user.reservations.unsubmitted.count).to eq 0
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::BookingCalendarSteps, borrow_booking_calendar: true
end
