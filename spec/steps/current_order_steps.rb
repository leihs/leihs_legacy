require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module CurrentOrderSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I have an unsubmitted order' do
        FactoryGirl.create(:reservation,
                           user: @current_user,
                           status: :unsubmitted,
                           inventory_pool: @inventory_pool)
      end

      step 'each reservation line displays start and end date' do
        @current_user.reservations.unsubmitted.each do |r|
          within ".line[data-ids*='#{r.id}']" do
            expect(page).to have_content \
              "#{I18n.l r.start_date} - #{I18n.l r.end_date}"
          end
        end
      end

      step 'I open the page for this order' do
        visit borrow_order_path
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::CurrentOrderSteps, borrow_current_order: true
end
