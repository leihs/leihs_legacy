require_relative 'shared/common_steps'
require_relative 'shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module DelegationSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::LoginSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps

      step 'there is a delegation' do
        @delegation = FactoryGirl.create(:delegation)
      end

      step 'there is no reservation of any kind for this delegation' do
        expect(Reservation.find_by_user_id(@delegation.id)).not_to be
      end

      step 'the delegation has no access rights to any inventory pool' do
        expect(
          AccessRight
          .where(user_id: @delegation.id)
          .where(role: [:customer,
                        :group_manager,
                        :lending_manager,
                        :inventory_manager])
          .exists?
        ).to be false
      end

      step 'I click on the dropdown toggle for the delegation' do
        find('.list-of-lines .row', text: @delegation.name)
          .find('.dropdown-toggle')
          .click
      end

      step 'the delegation doesn\'t exist anymore' do
        expect(User.find_by_id(@delegation.id)).not_to be
      end

      step 'I search after the delegation' do
        within '#list-filters' do
          fill_in 'search_term', with: @delegation.name
        end
        click_on _('Search')
      end

      step 'I see the line for the delegation' do
        find('.list-of-lines .row', text: @delegation.name)
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::DelegationSteps, leihs_admin_delegation: true
end
