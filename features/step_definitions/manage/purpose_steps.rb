# -*- encoding : utf-8 -*-

When /^a purpose is saved, it is independent of its orders$/ do
  purpose = FactoryBot.create :purpose
  expect { purpose.contract }.to raise_error(NoMethodError)
end

When /^each entry of a submitted order refers to a purpose$/ do
  reservations = rand(3..6).times.map { FactoryBot.create :reservation, status: :submitted }
  reservations.each do |line|
    expect(line.purpose.is_a?(Purpose)).to be true
  end
end

When /^each entry of an order can refer to a purpose$/ do
  reservations = rand(3..6).times.map { FactoryBot.create :reservation }
  reservations.each do |line|
    line.purpose = FactoryBot.create :purpose
    expect(line.purpose.is_a?(Purpose)).to be true
  end
end


Then /^I see the purpose$/ do
  expect(has_content?(@order.purpose)).to be true
end

Then /^I see the assigned purpose on each line$/ do
  @customer.reservations.approved.where(inventory_pool_id: @current_inventory_pool).each do |line|
    target = find(".line[data-id='#{line.id}'] [data-tooltip-template*='purpose']")
    hover_for_tooltip target
    find('.tooltipster-default .tooltipster-content', text: line.order.purpose)
  end
end

Then /^I can edit the purpose$/ do
  find('.button', text: _('Edit Purpose')).click
  @new_purpose_description = 'Benötigt für die Sommer-Austellung'
  within '.modal' do
    find("textarea[name='purpose']").set @new_purpose_description
    find('button[type=submit]').click
  end
  find('#purpose', text: @new_purpose_description)
  expect(@order.reload.purpose).to eq @new_purpose_description
end

When /^none of the selected items have an assigned purpose$/ do
  step 'I add an item to the hand over by providing an inventory code'
  step 'I add an option to the hand over by providing an inventory code'
  step 'I edit the timerange of the selection'
  step "I set the start date in the calendar to '#{I18n.l(Date.today)}'"
  step 'I save the booking calendar'
  step 'the booking calendar is closed'
end

Then /^I am told during hand over to assign a purpose$/ do
  find('.multibutton .button[data-hand-over-selection]').click
  within '.modal' do
    find('#purpose-input', text: _("Please provide a purpose...")).find('#purpose')
  end
end

Then /^only when I assign a purpose$/ do
  within '.modal' do
    find('.button.green[data-hand-over]', text: _('Hand Over')).click
    find('#error')
    find('#purpose').set 'The purpose for this hand over'
  end
end

Given(/^the current inventory pool (requires|doesn't require) purpose$/) do |arg1|
  b = case arg1
        when "requires"
          true
        else
          false
      end
  @current_inventory_pool.update(required_purpose: b)
end

Then /^I do not assign a purpose$/ do
  within '.modal' do
    expect(find('#purpose').text).to be_empty
  end
end

Then /^I can finish the hand over$/ do
  signed_contracts_size = @customer.contracts.open.to_a.size # NOTE count returns a Hash because the group() in default scope
  step 'I click hand over inside the dialog'
  expect(@customer.contracts.open.to_a.size).to be > signed_contracts_size # NOTE count returns a Hash because the group() in default scope
end

Then /^I don't have to assign a purpose in order to finish the hand over$/ do
  step 'I edit the timerange of the selection'
  step "I set the start date in the calendar to '#{I18n.l(Date.today)}'"
  step 'I save the booking calendar'
  step 'the booking calendar is closed'
  find('.multibutton .button[data-hand-over-selection]').click
  find('.modal.ui-shown')
  step 'I can finish the hand over'
end

When /^I define a purpose$/ do
  step 'I edit the timerange of the selection'
  step "I set the start date in the calendar to '#{I18n.l(Date.today)}'"
  step 'I save the booking calendar'
  step 'the booking calendar is closed'
  find('.multibutton .button[data-hand-over-selection]').click
  find('#add-purpose').click
  @added_purpose = 'Another Purpose'
  find('#purpose').set @added_purpose
  @approved_lines = @customer.orders.approved.find_by(inventory_pool_id: @current_inventory_pool).reservations
  step 'I can finish the hand over'
end

Then /^only items without purpose are assigned that purpose$/ do
  @approved_lines.select{|l| l.purpose.blank?}.each do |line|
    expect(line.purpose.description).to eq @added_purpose
  end
end

When /^all selected items have an assigned purpose$/ do
  @contract = @customer.orders.approved.find_by(inventory_pool_id: @current_inventory_pool)
  reservations = @contract.reservations
  reservations.each do |line|
    @item_line = line
    begin
      step 'I select one of those'
    rescue
      # if we ran out of available items, and an Capybara::Element not found exception was raised, just ensure that all the selected and assigned contract reservations so far, have a purpose
      expect(reservations.reload.select(&:item).all?(&:purpose)).to be true
      break
    end
  end

  # select all reservations if no one is selected yet
  if all("input[type='checkbox']:checked").empty?
    step 'I select all reservations selecting all linegroups'
  end
  # ensure that only reservations with assigned items are selected before continuing with the test
  reservations.reload.select{|l| !l.item}.each do |l|
    cb = find(".line[data-id='#{l.id}'] input[type='checkbox']")
    cb.click if cb.checked?
  end

  step 'I edit the timerange of the selection'
  step "I set the start date in the calendar to '#{I18n.l(Date.today)}'"
  step 'I save the booking calendar'
  step 'the booking calendar is closed'

  within '#lines' do
    reservations = reservations.select {|line| line.item and find(".line[data-id='#{line.id}'] input[type='checkbox'][data-select-line]").checked? }
  end

  find('.multibutton .button[data-hand-over-selection]').click
  within('.modal') do
    reservations.each do |line|
      find('.row', match: :first, text: line.purpose.to_s)
    end
  end
end

Then /^I cannot assign any more purposes$/ do
  expect(has_no_selector?('.modal .purpose button', visible: true)).to be true
end

When(/^I click on hand over$/) do
  find('[data-hand-over-selection]').click
end

When(/^I add a purpose$/) do
  within '.modal' do
    find('#add-purpose').click
    @additional_purpose = Faker::Lorem.sentence
    find('#purpose').set @additional_purpose
  end
end

When(/^I finish the hand over$/) do
  @contract_window = window_opened_by do
    find('.modal [data-hand-over]').click
  end
end

Then(/^the contract has the original plus the added purpose$/) do
  page.driver.browser.switch_to.window(@contract_window.handle)
  within '.purposes' do
    expect(current_scope).to have_content @purpose
    expect(current_scope).to have_content @additional_purpose
  end
end

Then(/^there is an approved and assigned reservation with purpose for a customer$/) do
  @customer = FactoryBot.create(:customer, inventory_pool: @current_inventory_pool)
  @purpose = Faker::Lorem.sentence
  @reservation = FactoryBot.create(:item_line, :with_assigned_item, :with_purpose,
                                    purpose: @purpose,
                                    user: @customer,
                                    inventory_pool: @current_inventory_pool,
                                    status: :approved)
end

Then(/^I open the hand over page for this customer$/) do
  visit manage_hand_over_path(@current_inventory_pool, @customer)
end

Then(/^I select this reservation$/) do
  find("[data-id='#{@reservation.id}'] [data-select-line]").click
end

Given(/^there is another approved and assigned reservation with purpose for a customer$/) do
  @another_purpose = Faker::Lorem.sentence
  @another_reservation = FactoryBot.create(:item_line, :with_assigned_item, :with_purpose,
                                            purpose: @another_purpose,
                                            user: @customer,
                                            inventory_pool: @current_inventory_pool,
                                            status: :approved)
end

Then(/^the contract has both the purposes$/) do
  page.driver.browser.switch_to.window(@contract_window.handle)
  within '.purposes' do
    expect(current_scope).to have_content @purpose
    expect(current_scope).to have_content @another_purpose
  end
end

