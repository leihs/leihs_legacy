require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module RejectedOrderReasonSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      LONG_REJECT_REASON =
        'Extensions may be requested here https://intern.example.test/773889 ' \
        '(in German) at the latest 1 day before the due return date. ' \
        'A new reservation is not an extension.'

      step 'a rejected order with a long reject reason exists for the customer' do
        pool = @inventory_pool || @current_inventory_pool
        @reject_reason = LONG_REJECT_REASON
        @order = FactoryBot.create(:order,
                                    inventory_pool: pool,
                                    user: @customer,
                                    state: :rejected,
                                    reject_reason: @reject_reason)
        FactoryBot.create(:reservation,
                           inventory_pool: pool,
                           user: @customer,
                           status: :rejected,
                           order: @order)
      end

      step 'I open the orders list' do
        pool = @inventory_pool || @current_inventory_pool
        visit manage_orders_path(pool,
                                 state: [:approved, :submitted, :rejected])
      end

      step 'the reject reason is shown on the order line' do
        expect(page).to have_selector('[data-reject-reason]',
                                      text: @reject_reason,
                                      wait: 15)
      end

      step 'the rejected order line does not overflow horizontally' do
        overflow = page.evaluate_script(<<~JS)
          (function() {
            var line = document.querySelector(
              '#contracts .line[data-type="order"]'
            );
            var reason = document.querySelector('[data-reject-reason]');
            if (!line || !reason) return false;
            return line.scrollWidth <= line.clientWidth + 1 &&
              reason.scrollWidth <= reason.clientWidth + 1;
          })()
        JS
        expect(overflow).to eq(true)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::RejectedOrderReasonSteps,
                 manage_rejected_order_reason: true
end
