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
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::HandOverSteps,
                 manage_hand_over: true
end
