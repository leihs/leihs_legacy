# -*- encoding : utf-8 -*-

Given /^I open a value list$/ do
  #step 'man öffnet einen Vertrag bei der Aushändigung'
  step 'I open a contract during hand over'
  @user = @hand_over.user

  page.driver.browser.close
  new_window = page.driver.browser.window_handles.last
  page.driver.browser.switch_to.window new_window

  new_window = window_opened_by do
    find('.modal a', text: _('Value List')).click
  end
  page.driver.browser.switch_to.window new_window.handle

  @list_element = find('.value_list')
end

Then /^I want to see the following sections in the (value list|picking list):$/ do |arg1, table|
  within @list_element do
    table.hashes.each do |area|
      case area['Section']
        when 'Date'
          within('.date') do
            expect(has_content? Date.today.year).to be true
            expect(has_content? Date.today.month).to be true
            expect(has_content? Date.today.day).to be true
          end
        when 'Title'
          case arg1
            when 'value list'
              expect(find('h1', text: _('Value List')).has_content? @contract.compact_id).to be true
            when 'picking list'
              find('h1', text: _('Picking List'))
          end
        when 'Borrower'
          within('.customer') do
            expect(has_content? @user.firstname).to be true
            expect(has_content? @user.lastname).to be true
            expect(has_content? @user.address).to be true if @user.address
            expect(has_content? @user.zip).to be true
            expect(has_content? @user.city).to be true
          end
        when 'Lender'
          find('.inventory_pool')
        when 'List'
          case arg1
            when 'value list'
              find('.list')
            when 'picking list'
              find('.list', match: :first)
          end
      end
    end
  end
end

Then /^the list contains the following columns:$/ do |table|
  @list ||= @list_element.find('.list')
  within @list do
    table.hashes.each do |area|
      case area['Column']
        when 'Consecutive number'
          @contract.reservations.each {|line| find('tr', text: line.item.inventory_code).find('.consecutive_number') }
        when 'Inventory code'
          reservations =
            if @list_element[:class] == 'picking_list'
              @selected_lines_by_date ? @selected_lines_by_date : @contract.reservations
            elsif @list_element[:class] == 'value_list'
              @contract.reservations
            else
              raise
            end
          reservations.each do |line|
            next if line.item_id.nil?
            find('tr .inventory_code', text: line.item.inventory_code)
          end
        when 'Model name'
          if @list_element[:class] == 'picking_list'
            reservations = @selected_lines_by_date ? @selected_lines_by_date : @contract.reservations
            reservations.group_by(&:model).each_pair do |model, reservations|
              find('tr', match: :prefer_exact, text: model).find('.model_name', text: model.name)
            end
          elsif @list_element[:class] == 'value_list'
            @contract.reservations.each {|line| find('tr', text: line.item.inventory_code).find('.model_name', text: line.model.name) }
          else
            raise
          end
        when 'End date'
          @contract.reservations.each {|line|
            within find('tr', text: line.item.inventory_code).find('.end_date') do
              expect(has_content? line.end_date.year).to be true
              expect(has_content? line.end_date.month).to be true
              expect(has_content? line.end_date.day).to be true
            end
          }
        when 'Quantity'
          if @list_element[:class] == 'picking_list'
            picking_lines = @selected_lines_by_date ? @selected_lines_by_date : @contract.reservations
            picking_lines.group_by(&:model).each_pair do |model, reservations|
              find('tr', match: :prefer_exact, text: model).find('.quantity', text: reservations.sum(&:quantity))
            end
          elsif @list_element[:class] == 'value_list'
            @contract.reservations.each {|line|
              find('tr', text: line.item.inventory_code).find('.quantity', text: line.quantity)
            }
          else
            raise
          end
        when 'Price'
          @contract.reservations.each {|line|
            expect(find('tbody tr', text: line.item.inventory_code).find('.item_price').text.gsub(/\D/, '')).to eq ('%.2f' % line.price).gsub(/\D/, '')
          }
        when 'Room / Shelf'
          find('table thead tr td.location', text: '%s / %s' % [_('Room'), _('Shelf')])
          reservations = @selected_lines_by_date ? @selected_lines_by_date : @contract.reservations
          reservations.each {|line|
            find('tbody tr', text: line.item ? line.item.inventory_code : line.model.name).find('.location', text:
                if line.model.is_a?(Option)
                  _('Location not defined')
                else
                  '%s / %s' % [line.item.room.name, line.item.shelf]
                end)
          }
        when 'available quantity x Room / Shelf'
          find('table thead tr td.location', text: '%s x %s / %s' % [_('available quantity'), _('Room'), _('Shelf')])
          reservations = @selected_lines_by_date ? @selected_lines_by_date : @contract.reservations
          reservations.each do |line|
            within find('tr', match: :prefer_exact, text: line.model).find('.location') do
              if line.model.is_a?(Option)
                _('Location not defined')
              else
                locations = line.model.items.in_stock.where(inventory_pool_id: @current_inventory_pool).select('COUNT(items.id) AS count, rooms.name AS room_name, items.shelf AS shelf').joins(:room).group('rooms.id', 'rooms.name', 'items.shelf').order('count DESC')
                locations.each do |location|
                  if line.item_id
                    find('tr', text: '%s / %s' % [location.room_name, location.shelf])
                  else
                    find('tr', text: '%dx %s' % [location.count, [location.room_name, location.shelf.presence].compact.join(' / ')])
                  end
                end
              end
            end
          end
        else
          raise
      end
    end
  end
end

Then /^one line shows the grand total$/ do
  within @list_element.find('.list') do
    @total = find('tfoot.total')
  end
end

Then /^that shows the totals of the columns:$/ do |table|
  table.hashes.each do |area|
    case area['Column']
      when 'Quantity'
        expect(@total.find('.quantity', match: :first).has_content? @contract.total_quantity).to be true
      when 'Value'
        expect(@total.find('.value', match: :first).text.gsub(/\D/, '')).to eq ('%.2f' % @contract.reservations.map(&:price).sum).gsub(/\D/, '')
    end
  end
end

When(/^the models in the value list are sorted alphabetically$/) do
  names = all('.value_list tbody .model_name').map{|name| name.text}
  expect(names.empty?).to be false
  expect(names.sort == names).to be true
end

Given(/^there is an order with at least two models and at least two items per model were ordered$/) do
  @hand_over = @current_inventory_pool.visits.hand_over.detect do |ho|
    ho.reservations.where(type: 'OptionLine').exists? and
      ho.reservations.where(type: 'ItemLine').exists? and
        (g = ho.reservations.where(type: 'ItemLine').group_by(&:model_id)) and
          g.keys.size >= 2 and
            g.values.detect {|x| x.size >= 3}
  end
  expect(@hand_over).not_to be_nil
  @reservations = @hand_over.reservations
end

When(/^each model has exactly one assigned item$/) do
  @models = @reservations.select{|l| l.is_a? ItemLine}.map(&:model)

  @models.uniq.each do |m|
    l = @reservations.find{|l| l.model == m}
    l.update_attribute(:item, l.model.borrowable_items.where(inventory_pool_id: @current_inventory_pool).first) unless l.is_a? OptionLine
  end
end

When(/^I select multiple reservations of the (order|hand over)$/) do |arg1|
  within '#lines' do
    expect(has_selector?(".line input[type='checkbox']")).to be true
    case arg1
      when 'order'
        @number_of_selected_lines = @order.reservations.size
        all(".emboss .row input[type='checkbox']").each {|i| i.click unless i.checked? }
      when 'hand over'
        @number_of_selected_lines = all(".line input[type='checkbox']").size
        @reservations.map(&:id).each do |id|
          cb = find(".line[data-id='#{id}'] input[type='checkbox']")
          cb.click unless cb.checked?
        end
    end
  end
end

When(/^I open the value list$/) do
  find('[data-selection-enabled]').find(:xpath, './following-sibling::*').click
  document_window = window_opened_by do
    click_button _('Print Selection')
  end
  page.driver.browser.switch_to.window(document_window.handle)
end

Then(/^I see the value list for the selected reservations$/) do
  expect(has_content? _('Value List')).to be true
  find('tfoot.total .quantity').text == @number_of_selected_lines.to_s
end

Then(/^the price shown for the unassigned reservations is equal to the highest price of any of the items of that model within this inventory pool$/) do
  @models.each do |m|
    reservations = @reservations.select {|l| l.is_a? ItemLine and l.model == m and not l.item.try(:inventory_code)}
    quantity = reservations.size
    line = all('tr', text: m.name).find {|line| line.find('.inventory_code').text == '' }
    if line
      price = @reservations.reload.find{|l| not l.item and l.model == m}.price_or_max_price * quantity
      formatted_price = ActionController::Base.helpers.number_to_currency(price, format: '%n %u', unit: Setting.first.local_currency_string)
      line.find('.item_price', text: formatted_price)
    end
  end
end

Then(/^the price shown for the assigned reservations is that of the assigned item$/) do
  reservations = @reservations.select {|l| l.item.try(:inventory_code)}
  reservations.each do |line|
    formatted_price = ActionController::Base.helpers.number_to_currency(line.price_or_max_price, format: '%n %u', unit: Setting.first.local_currency_string)
    find('tr', text: line.item.inventory_code).find('.item_price', text: formatted_price)
  end
end

Then(/^the unassigned reservations are summarized$/) do
  @models.each do |m|
    expect(all('tr', text: m.name).select{|line| line.find('.inventory_code').text == '' }.size).to be <= 1 # for models with quantity 1 and an assigned item size == 0, that's why <= 1
  end
end

Then(/^any options are priced according to their price set in the inventory pool$/) do
  reservations = @reservations.select {|l| l.is_a? OptionLine }
  reservations.each do |l|
    line = find('tr', text: l.model.name)
    formatted_price = ActionController::Base.helpers.number_to_currency(@current_inventory_pool.options.find(l.item.id).price * l.quantity, format: '%n %u', unit: Setting.first.local_currency_string)
    line.find('.item_price', text: formatted_price)
  end
end

Given(/^there is an order with at least two models and a quantity of at least three per model$/) do
  customer = FactoryBot.create(:customer, inventory_pool: @current_inventory_pool)
  @order = FactoryBot.create(:order, state: :submitted, user: customer, inventory_pool: @current_inventory_pool)
  [FactoryBot.create(:model), FactoryBot.create(:model)].each do |model|
    3.times do
      @order.reservations << FactoryBot.create(:reservation,
                                                user: customer,
                                                inventory_pool: @current_inventory_pool,
                                                order: @order,
                                                status: :submitted,
                                                model: model)
    end
  end
  expect(@order).not_to be_nil
  @reservations = @order.reservations
  @models = @reservations.select{|l| l.is_a? ItemLine}.map(&:model)
end

When(/^I open an order$/) do
  step 'there is an order with at least two models and a quantity of at least three per model'
  @contract = @order
  step 'I edit the order'
end
