require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module HandOverSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'a customer for my inventory pool exists' do
        @inventory_pool = @current_user.inventory_pools.managed.first
        @customer = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)
      end

      step 'an item owned by my inventory pool exists' do
        @item = FactoryGirl.create(:item, owner: @inventory_pool)
      end

      step 'a license owned by my inventory pool exists' do
        @license = FactoryGirl.create(:license, owner: @inventory_pool)
      end

      step 'the customer has borrowed the item for today' do
        FactoryGirl.create(:signed_contract,
                           user: @customer,
                           inventory_pool: @inventory_pool,
                           start_date: Date.today,
                           end_date: Date.tomorrow,
                           items: [@item])
      end

      step 'I open hand over for the user' do
        visit manage_hand_over_path(@inventory_pool, @customer)
      end

      step 'I try to assign the item for today' do
        within '#assign-or-add' do
          find('#add-start-date').set I18n.l(Date.today)
          find('#add-end-date').set I18n.l(Date.tomorrow)
          find('#assign-or-add-input input').set @item.inventory_code
          find('button.addon').click
        end
      end

      step 'I see an error message that the item ' \
           'is already assigned to a contract' do
        expect(find('#flash .error').text)
          .to match \
            /#{@item.inventory_code} is already assigned to a different contract/
      end

      step 'the reservation line was not created' do
        visit manage_hand_over_path(@inventory_pool, @customer)
        expect(Reservation.where(item_id: @item.id).count).to be == 1
        expect(find('#lines').text).to be_blank
      end

      step "I enter the item's model name in the :add_assign input field" \
        do |add_assign|
        raise unless add_assign == 'Add/Assign'
        find('#assign-or-add-input input').set @item.model.name
      end

      step "I choose the item's model name from the displayed dropdown" do
        within '.ui-autocomplete' do
          find('a', text: @item.model.name).click
        end
      end

      step "a reservation line for the item's model name was added" do
        within '#lines' do
          find('.line', text: @item.model.name)
        end
      end

      step "I enter the license's model name in the :add_assign input field" \
        do |add_assign|
        raise unless add_assign == 'Add/Assign'
        find('#assign-or-add-input input').set @license.model.name
      end

      step "I choose the license's model name from the displayed dropdown" do
        within '.ui-autocomplete' do
          find('a', text: @license.model.name).click
        end
      end

      step "a reservation line for the license's model name was added" do
        within '#lines' do
          find('.line', text: @license.model.name)
        end
      end

      step 'I assign the item to its model line' do
        find('#lines .line', text: @item.model.name)
          .find('[data-assign-item-form] input')
          .set @item.inventory_code
        find('.ui-autocomplete a', text: @item.inventory_code).click
      end

      step 'I assign the license to its model line' do
        find('#lines .line', text: @license.model.name)
          .find('[data-assign-item-form] input')
          .set @license.inventory_code
        find('.ui-autocomplete a', text: @license.inventory_code).click
      end

      step 'I click on "Hand Over Selection"' do
        click_on _('Hand Over Selection')
      end

      step 'I enter the purpose' do
        within '.modal' do
          fill_in 'purpose', with: Faker::Lorem.sentence
        end
      end

      step 'I click on "Hand Over"' do
        click_on _('Hand Over')
      end

      step 'I switch to the contract window' do
        wait_until do
          page.driver.browser.window_handles.count > 1
        end
        last_window = page.driver.browser.window_handles.last
        page.driver.browser.switch_to.window last_window
      end

      step 'the contract includes the inventory code of the item' do
        within '.contract' do
          page.should have_content @item.inventory_code
        end
      end

      step 'the contract includes the inventory code of the license' do
        within '.contract' do
          page.should have_content @item.inventory_code
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::HandOverSteps,
                 manage_hand_over: true
end
