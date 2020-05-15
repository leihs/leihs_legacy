require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module TakeBackSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there exists an open contract' do
        user = FactoryGirl.create(:customer,
                                  inventory_pool: @current_inventory_pool)
        @contract = FactoryGirl.create(:open_contract,
                                       inventory_pool: @current_inventory_pool,
                                       user: user)
      end

      step 'the contract has an item line' do
        @option_line = \
          FactoryGirl.create(:option_line,
                             user: @contract.user,
                             inventory_pool: @contract.inventory_pool,
                             contract: @contract,
                             status: :signed)
      end

      step 'the contract has an option line' do
        @item_line = \
          FactoryGirl.create(:item_line, :with_assigned_item,
                             user: @contract.user,
                             inventory_pool: @contract.inventory_pool,
                             contract: @contract,
                             status: :signed)
      end

      step 'I open the take back page for the user of this contract' do
        visit manage_take_back_path(@current_inventory_pool, @contract.user)
      end

      step 'I select all lines' do
        sleep 1
        find('[data-select-lines]')
        all('[data-select-lines]').map(&:click)
      end

      step 'within modal dialog I click on :label' do |label|
        within '.modal' do
          click_on _(label)
        end
      end

      step 'I see :text' do |text|
        expect(page).to have_content _(text)
      end

      step 'the contract is in state :state' do |state|
        expect(@contract.reload.state).to be == state
      end

      step 'all the reservations of the contract are :state' do |state|
        @contract.reload.reservations.each do |r|
          expect(r.status).to be == state.to_sym
        end
      end

      step 'I hover over the purpose icon of the item line' do
        find(".line[data-id='#{@item_line.id}'] .fa-comment").hover
      end

      step 'I hover over the purpose icon of the option line' do
        find(".line[data-id='#{@option_line.id}'] .fa-comment").hover
      end

      step 'I see the contract\'s purpose in the shown tooltip' do
        within '.tooltipster-base' do
          expect(current_scope).to have_content @contract.purpose
        end
      end

      step 'the user of the contract has no access to current inventory pool' do
        pool = @contract.inventory_pool
        @user = @contract.user
        @user.access_right_for(pool).try(:destroy!)
      end

      step 'I see :label next to user\'s name' do |label|
        within find("[data-id='#{@user.id}']") do
          expect(current_scope).to have_content _("No access")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::TakeBackSteps,
                 manage_take_back: true
end
