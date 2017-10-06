require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module ListOfOrdersSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I have a submitted order' do
        order = FactoryGirl.create(:order,
                                   state: :submitted,
                                   user: @current_user,
                                   inventory_pool: @inventory_pool)
        FactoryGirl.create(:reservation,
                           user: @current_user,
                           status: :submitted,
                           order: order,
                           inventory_pool: @inventory_pool)
      end

      step 'each reservation line displays start and end date' do
        @current_user.reservations.submitted.each do |r|
          within ".line[data-ids*='#{r.id}']" do
            expect(page).to have_content \
              "#{I18n.l r.start_date} - #{I18n.l r.end_date}"
          end
        end
      end

      step 'I open the list of orders page' do
        visit borrow_orders_path
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::ListOfOrdersSteps, borrow_list_of_orders: true
end
