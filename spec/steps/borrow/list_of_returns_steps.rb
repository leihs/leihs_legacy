require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module ListOfReturnsSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I have an open contract' do
        FactoryGirl.create(:open_contract,
                           user: @current_user,
                           inventory_pool: @inventory_pool)
      end

      step 'each reservation line displays start and end date' do
        @current_user.reservations.signed.each do |r|
          within ".line[data-line-id='#{r.id}']" do
            expect(page).to have_content \
              "#{I18n.l r.start_date} - #{I18n.l r.end_date}"
          end
        end
      end

      step 'I open the list of returns page' do
        visit borrow_returns_path
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::ListOfReturnsSteps, borrow_list_of_returns: true
end
