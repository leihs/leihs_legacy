require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module PickupLocationLendingSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'the current pool has alternative pickup locations enabled' do
        pool = @current_inventory_pool || @inventory_pool
        pool.update!(enable_alternative_pickup_locations: true)
      end

      step 'the customer has an approved reservation for the item ' \
           'with an alternative pickup location' do
        create_approved_pickup_reservation(@item)
      end

      step 'the customer has an approved reservation for the first item ' \
           'with an alternative pickup location' do
        create_approved_pickup_reservation(@item)
      end

      step 'the customer has an approved reservation for the item ' \
           'without an alternative pickup location' do
        pool = @inventory_pool || @current_inventory_pool
        @reservation = FactoryBot.create(
          :reservation,
          status: :approved,
          user: @customer,
          inventory_pool: pool,
          model: @item.model,
          item: @item,
          start_date: Date.today,
          end_date: Date.tomorrow
        )
      end

      def ensure_pickup_location
        pool = @inventory_pool || @current_inventory_pool
        @pickup_location ||= FactoryBot.create(:pickup_location,
                                               inventory_pool: pool,
                                               name: 'Alt Desk')
      end

      def create_open_contract_for_items(items, pickup_location: false)
        pool = @inventory_pool || @current_inventory_pool
        contract = FactoryBot.create(:open_contract,
                                     user: @customer,
                                     inventory_pool: pool,
                                     start_date: Date.today,
                                     end_date: Date.tomorrow,
                                     items: items)
        if pickup_location
          ensure_pickup_location
          contract.reservations.each do |reservation|
            reservation.update!(pickup_location: @pickup_location)
          end
        end
        contract
      end

      def create_approved_pickup_reservation(item)
        pool = @inventory_pool || @current_inventory_pool
        @pickup_location ||= FactoryBot.create(:pickup_location,
                                               inventory_pool: pool,
                                               name: 'Alt Desk')
        @reservation = FactoryBot.create(
          :reservation,
          status: :approved,
          user: @customer,
          inventory_pool: pool,
          model: item.model,
          item: item,
          pickup_location: @pickup_location,
          start_date: Date.today,
          end_date: Date.tomorrow
        )
      end

      step 'the customer has an approved reservation for the second item ' \
           'without a pickup location starting later' do
        pool = @inventory_pool || @current_inventory_pool
        @warehouse_reservation = FactoryBot.create(
          :reservation,
          status: :approved,
          user: @customer,
          inventory_pool: pool,
          model: @item_2.model,
          item: @item_2,
          start_date: Date.today + 7,
          end_date: Date.today + 8
        )
      end

      step 'the customer has borrowed the item for today' do
        create_open_contract_for_items([@item])
      end

      step 'the customer has borrowed the item for today ' \
           'with an alternative pickup location' do
        create_open_contract_for_items([@item], pickup_location: true)
      end

      step 'the item model is not transportable' do
        @item.model.update!(transportable: false)
      end

      step 'the first item model is not transportable' do
        @item.model.update!(transportable: false)
      end

      step 'I open hand over for the user' do
        visit manage_hand_over_path(@inventory_pool, @customer)
      end

      step 'I open take back for the user' do
        visit manage_take_back_path(@inventory_pool, @customer)
      end

      step 'the pickup location is not shown on the hand over line' do
        within '#lines' do
          expect(page).not_to have_selector('[data-pickup-location]')
        end
      end

      step 'the handed to courier checkbox is not shown on the hand over line' do
        within '#lines' do
          expect(page).not_to have_selector('[data-toggle-courier-to-pickup]')
        end
      end

      step 'the pickup location is shown on the hand over line' do
        within '#lines' do
          expect(page).to have_selector('[data-pickup-location].orange-text',
                                        text: @pickup_location.name)
        end
      end

      step 'the handed to courier checkbox is shown on the hand over line' do
        within '#lines' do
          courier = find('[data-toggle-courier-to-pickup]')
          expect(courier).to be_present
          parent = courier.find(:xpath, './ancestor::div[contains(@class,"line-col")][1]')
          expect(parent[:class]).to include('col2of10')
          expect(parent[:class]).not_to include('col3of10')
        end
      end

      step 'I check the handed to courier checkbox on the hand over line' do
        within '#lines' do
          find('[data-toggle-courier-to-pickup]').set(true)
        end
        expect(page).to have_selector('[data-toggle-courier-to-pickup]:checked')
      end

      step 'the reservation is marked as sent to the pickup location' do
        expect(@reservation.reload.sent_to_pickup_location_at).to be_present
        expect(@reservation.sent_to_pickup_location_by_user_id)
          .to eq @current_user.id
      end

      step 'the reservation is still approved without a contract' do
        @reservation.reload
        expect(@reservation.status).to eq :approved
        expect(@reservation.contract_id).to be_nil
      end

      step 'the handed to courier checkbox is shown on the take back line' do
        within '#lines' do
          expect(page).to have_selector('[data-toggle-courier-to-main]')
        end
      end

      step 'the handed to courier checkbox is not shown on the take back line' do
        expect(page).to have_content('Availability loaded')
        within '#lines' do
          expect(page).not_to have_selector('[data-toggle-courier-to-main]')
        end
      end

      step 'the pickup location is not shown on the take back line' do
        within '#lines' do
          expect(page).not_to have_selector('[data-pickup-location]')
        end
      end

      step 'the handed to courier checkbox is shown only on the take back ' \
           'line for the second item' do
        expect(page).to have_content('Availability loaded')
        within '#lines' do
          expect(page).to have_selector('[data-toggle-courier-to-main]', count: 1)
          second_line = find('.line', text: @item_2.inventory_code)
          expect(second_line).to have_selector('[data-toggle-courier-to-main]')
          first_line = find('.line', text: @item.inventory_code)
          expect(first_line).to have_no_selector('[data-toggle-courier-to-main]')
        end
      end

      step 'the courier select-all checkbox is shown on the take back group' do
        within '#lines' do
          expect(page).to have_selector('[data-select-courier-lines]',
                                        visible: true)
        end
      end

      step 'I check the handed to courier checkbox on the take back line' do
        within '#lines' do
          find('[data-toggle-courier-to-main]').set(true)
        end
        expect(page).to have_selector('[data-toggle-courier-to-main]:checked')
      end

      step 'the reservation is marked as sent back to the main location' do
        reservation = Reservation.signed
          .where(item_id: @item.id, user_id: @customer.id)
          .first
        expect(reservation.sent_back_to_main_location_at).to be_present
        expect(reservation.sent_back_to_main_location_by_user_id)
          .to eq @current_user.id
        @signed_reservation = reservation
      end

      step 'the reservation is still signed and not returned' do
        @signed_reservation.reload
        expect(@signed_reservation.status).to eq :signed
        expect(@signed_reservation.returned_date).to be_nil
      end

      step 'the pickup location and courier checkbox are fully visible ' \
           'on the hand over line' do
        within '#lines' do
          expect(find('[data-pickup-location]')).to be_visible
          expect(find('[data-toggle-courier-to-pickup]')).to be_visible
        end
        overflow = page.evaluate_script(<<~JS)
          (function() {
            var el = document.querySelector('#lines .line[data-line-type="item_line"]');
            if (!el) return false;
            return el.scrollHeight <= el.clientHeight + 1;
          })()
        JS
        expect(overflow).to eq(true)
      end

      step 'two items owned by my inventory pool exist' do
        @item = FactoryBot.create(:item, owner: @inventory_pool)
        @item_2 = FactoryBot.create(:item, owner: @inventory_pool)
      end

      step 'the customer has borrowed both items for today' do
        create_open_contract_for_items([@item, @item_2])
      end

      step 'the customer has borrowed both items for today ' \
           'with an alternative pickup location' do
        create_open_contract_for_items([@item, @item_2], pickup_location: true)
      end

      step 'the customer has borrowed both items for today, ' \
           'the second with an alternative pickup location' do
        contract = create_open_contract_for_items([@item, @item_2])
        ensure_pickup_location
        reservation = contract.reservations.find { |r| r.item_id == @item_2.id }
        reservation.update!(pickup_location: @pickup_location)
      end

      step 'I select both take back lines' do
        expect(page).to have_content('Availability loaded')
        within '#lines' do
          ids = all('[data-id][data-line-type="item_line"]', minimum: 2)
            .map { |el| el['data-id'] }
          ids.each do |id|
            find("[data-id='#{id}'] [data-select-line]").set(true)
          end
        end
        expect(page).to have_selector('[data-select-line]:checked', minimum: 2)
      end

      step 'I check the handed to courier checkbox on the first take back line' do
        within '#lines' do
          first('[data-toggle-courier-to-main]').set(true)
        end
        expect(page).to have_selector('[data-toggle-courier-to-main]:checked',
                                      count: 1, wait: 10)
        expect(page).to have_selector('[data-toggle-courier-to-main]:not(:checked)',
                                      count: 1)
      end

      step 'I check the courier select-all checkbox for the group' do
        within '#lines' do
          find('[data-select-courier-lines]', visible: true).set(true)
        end
        expect(page).to have_selector('[data-toggle-courier-to-main]:checked',
                                      minimum: 2, wait: 10)
      end

      step 'only the first reservation is marked as sent back to the main location' do
        first_line_id = page.evaluate_script(<<~JS)
          document.querySelector('[data-toggle-courier-to-main]:checked')
            .closest('[data-id]').getAttribute('data-id')
        JS
        sent = []
        Timeout.timeout(Capybara.default_max_wait_time) do
          loop do
            reservations = Reservation.signed.where(user_id: @customer.id)
            sent = reservations.select do |reservation|
              reservation.reload.sent_back_to_main_location_at.present?
            end
            break if sent.count == 1
            sleep 0.2
          end
        end
        expect(sent.count).to eq 1
        expect(sent.first.id.to_s).to eq first_line_id.to_s
        expect(sent.first.sent_back_to_main_location_by_user_id)
          .to eq @current_user.id
        @signed_reservations = Reservation.signed.where(user_id: @customer.id)
      end

      step 'the courier select-all checkbox is shown for the group ' \
           'with the pickup location' do
        within '#lines' do
          container = find('[data-toggle-courier-to-pickup]')
            .find(:xpath, './ancestor::*[@data-selected-lines-container][1]')
          expect(container).to have_selector('[data-select-courier-lines]',
                                             visible: true)
        end
      end

      step 'the courier select-all checkbox is not shown for the group ' \
           'without a pickup location' do
        within '#lines' do
          containers = all('[data-selected-lines-container]', minimum: 2)
          warehouse = containers.find do |container|
            container.has_no_selector?('[data-toggle-courier-to-pickup]', wait: 0)
          end
          expect(warehouse).to be_present
          expect(warehouse).to have_no_selector('[data-select-courier-lines]',
                                                visible: true)
        end
      end

      step 'both reservations are marked as sent back to the main location' do
        reservations = nil
        Timeout.timeout(Capybara.default_max_wait_time) do
          loop do
            reservations = Reservation.signed.where(user_id: @customer.id)
            break if reservations.count == 2 &&
              reservations.all? { |r| r.reload.sent_back_to_main_location_at.present? }
            sleep 0.2
          end
        end
        expect(reservations.count).to eq 2
        reservations.each do |reservation|
          expect(reservation.sent_back_to_main_location_by_user_id)
            .to eq @current_user.id
        end
        @signed_reservations = reservations
      end

      step 'both reservations are still signed and not returned' do
        @signed_reservations.each do |reservation|
          reservation.reload
          expect(reservation.status).to eq :signed
          expect(reservation.returned_date).to be_nil
        end
      end

      step 'the customer has approved reservations for both items ' \
           'with an alternative pickup location' do
        @reservation = create_approved_pickup_reservation(@item)
        first_reservation = @reservation
        @reservation_2 = create_approved_pickup_reservation(@item_2)
        # create_approved_pickup_reservation assigns @reservation; restore the first
        @reservation = first_reservation
      end

      step 'the second item model has three non-adjacent unavailable ' \
           'periods within the reservation range' do
        pool = @inventory_pool || @current_inventory_pool
        start_date = pool.next_open_date(Date.today)
        end_date = start_date
        14.times { end_date = pool.next_open_date(end_date + 1.day) }

        [@reservation, @reservation_2].each do |reservation|
          reservation.update!(start_date: start_date, end_date: end_date)
        end

        open_days = []
        day = start_date
        while day <= end_date
          open_days << day if pool.open_on?(day)
          day += 1.day
        end
        # Pick three non-adjacent open days inside the range (skip first/last)
        inner = open_days[1...-1]
        @unavailable_conflict_days = [inner[1], inner[3], inner[5]]
        expect(@unavailable_conflict_days.compact.uniq.size).to eq(3)

        other_customer = FactoryBot.create(:customer, inventory_pool: pool)
        @unavailable_conflict_days.each do |conflict_day|
          FactoryBot.create(
            :reservation,
            status: :approved,
            user: other_customer,
            inventory_pool: pool,
            model: @item_2.model,
            start_date: conflict_day,
            end_date: conflict_day
          )
        end
      end

      step 'the pickup location and handed to courier are shown only ' \
           'on the hand over line for the second item' do
        expect(page).to have_content('Availability loaded')
        within '#lines' do
          expect(page).to have_selector('[data-pickup-location]', count: 1)
          expect(page).to have_selector('[data-toggle-courier-to-pickup]', count: 1)

          first_line = find(".line[data-id='#{@reservation.id}']")
          expect(first_line).to have_no_selector('[data-pickup-location]')
          expect(first_line).to have_no_selector('[data-toggle-courier-to-pickup]')

          second_line = find(".line[data-id='#{@reservation_2.id}']")
          expect(second_line).to have_selector(
            '[data-pickup-location].orange-text',
            text: @pickup_location.name
          )
          expect(second_line).to have_selector('[data-toggle-courier-to-pickup]')
        end
      end

      step 'I select both hand over lines' do
        expect(page).to have_content('Availability loaded')
        within '#lines' do
          ids = all('[data-id][data-line-type="item_line"]', minimum: 2)
            .map { |el| el['data-id'] }
          ids.each do |id|
            find("[data-id='#{id}'] [data-select-line]").set(true)
          end
        end
        expect(page).to have_selector('[data-select-line]:checked', minimum: 2)
        expect(find('#line-selection-counter')).to have_text('2')
      end

      step 'I open Edit Selection' do
        find('[data-selection-multibutton] .dropdown-toggle').click
        find(
          "[data-selection-multibutton] [data-edit-lines='selected-lines']",
          text: _('Edit Selection')
        ).click
        expect(page).to have_selector('.modal #booking-calendar-lines', wait: 10)
        expect(page).to have_selector('.modal .fc-day-content', wait: 10)
        page.execute_script(<<~JS)
          var lines = document.querySelector('.modal #booking-calendar-lines');
          if (lines) { lines.scrollIntoView({ block: 'end', behavior: 'instant' }); }
        JS
      end

      step 'the pickup location is shown only for the transportable model ' \
           'in the edit reservation dialog' do
        within '.modal #booking-calendar-lines' do
          expect(page).to have_selector('[data-pickup-location]', count: 1)

          non_transportable = find('.line.row', text: @item.model.name)
          expect(non_transportable).to have_no_selector('[data-pickup-location]')

          transportable = find('.line.row', text: @item_2.model.name)
          pickup = transportable.find('[data-pickup-location]')
          expect(pickup).to be_visible
          expect(pickup[:class]).to include('orange-text')
          expect(pickup.text.strip)
            .to eq "#{_('Pickup location')}: #{@pickup_location.name}"
          font_weight = page.evaluate_script(<<~JS)
            window.getComputedStyle(
              document.querySelector(
                '.modal #booking-calendar-lines [data-pickup-location]'
              )
            ).fontWeight
          JS
          expect(font_weight.to_i).to be >= 700
        end
      end

      step 'three unavailable date ranges are shown for the transportable ' \
           'model in the edit reservation dialog' do
        within '.modal #booking-calendar-lines' do
          transportable = find('.line.row', text: @item_2.model.name)
          expect(transportable).to have_css(
            '.col4of10.line-col strong.darkred-text',
            count: 3
          )
          @unavailable_conflict_days.each do |day|
            formatted = page.evaluate_script(
              "moment('#{day.iso8601}').format(i18n.date.L)"
            )
            expect(transportable).to have_css(
              'strong.darkred-text',
              text: "#{formatted}-#{formatted}"
            )
          end
        end
      end

      step 'I open the edit reservation dialog for the line' do
        within '#lines' do
          find('.multibutton .button[data-edit-lines]', text: _('Change entry')).click
        end
        expect(page).to have_selector('.modal #booking-calendar-lines', wait: 10)
        expect(page).to have_selector('.modal .fc-day-content', wait: 10)
      end

      step 'the pickup location is shown under the model in the edit reservation dialog' do
        within '.modal #booking-calendar-lines' do
          row = find('.line.row', match: :first)
          model_col = row.find('.col5of10.line-col')
          expect(model_col).to have_css('strong', text: @reservation.model.name)
          pickup = model_col.find('[data-pickup-location]')
          expect(pickup).to be_visible
          expect(pickup[:class]).to include('orange-text')
          expect(pickup.text.strip).to eq "#{_('Pickup location')}: #{@pickup_location.name}"
        end
      end

      step 'the pickup location is not shown in the edit reservation dialog' do
        within '.modal #booking-calendar-lines' do
          expect(page).not_to have_selector('[data-pickup-location]')
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::PickupLocationLendingSteps,
                 manage_pickup_location_lending: true
end
