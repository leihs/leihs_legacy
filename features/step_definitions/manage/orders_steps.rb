# -*- encoding : utf-8 -*-

Then(/^I don't see empty orders in the list of orders$/) do
  find('nav a', text: _('Orders')).click
  within '#contracts' do
    expect(has_selector? '.line[data-id]').to be true
    all('.line[data-id]').each do |line|
      contract = @current_inventory_pool.orders.find(line['data-id'])
      expect(contract.reservations.empty?).to be false
    end
  end
end

When(/^I open a suspended user's order$/) do
  @order = @current_inventory_pool.orders.submitted.first
  ensure_suspended_user(@order.user, @current_inventory_pool)
  visit manage_edit_order_path(@current_inventory_pool, @order)
end

When(/^I see the note 'Suspended!' next to their name$/) do
  find('span.darkred-text', text: '%s!' % _('Suspended'))
end

def ensure_suspended_user(user, inventory_pool, suspended_until = rand(1.years.from_now..3.years.from_now).to_date, suspended_reason = Faker::Lorem.paragraph)
  unless user.suspended?(inventory_pool)
    user.access_rights.active.where(inventory_pool_id: inventory_pool).first.update(suspended_until: suspended_until, suspended_reason: suspended_reason)
    expect(user.suspended?(inventory_pool)).to be true
  end
end

Given(/^an order contains overbooked models$/) do
  @contract = @current_inventory_pool.orders.submitted.joins(:reservations).with_verifiable_user_and_model.detect {|c| not c.approvable?}
  expect(@contract).not_to be_nil
end

When(/^I edit this submitted contract$/) do
  visit manage_edit_order_path(@current_inventory_pool, @contract)
end

When(/^I approve the order$/) do
  if page.has_selector? 'button', text: _('Approve order')
    click_button _('Approve order')
  elsif page.has_selector? 'button', text: _('Verify + approve order')
    click_button _('Verify + approve order')
  end
end

Then(/^I cannot force the order to be approved$/) do
  expect(has_selector?('.modal')).to be true
  if page.has_selector? '.modal .multibutton .dropdown-toggle'
    find('.modal .multibutton .dropdown-toggle').click
  end
  expect(has_no_content?(_('Approve anyway'))).to be true
end

Then(/^I see the tabs "(.*?)"$/) do |tabs|
  within '.inline-tab-navigation' do
    tabs.split(', ').each do |tab|
      find('.inline-tab-item', text: tab)
    end
  end
end


Given(/^a verifiable order exists$/) do
  @contract = Order.joins(:reservations).with_verifiable_user_and_model.first
  expect(@contract).not_to be_nil
end

Then(/^this order was created by a user that is in a group whose orders require verification$/) do
  EntitlementGroup.where(is_verification_required: true).flat_map(&:users).uniq.include? @contract.user
end

Then(/^this order contains a model from a group whose orders require verification$/) do
  @contract.models.any? do |m|
    EntitlementGroup.where(is_verification_required: true).flat_map(&:models).uniq.include? m
  end
end

When(/^I view the tab "(.*?)"$/) do |tab|
  find('.inline-tab-navigation .inline-tab-item', text: tab).click
end

Then(/^I see all verifiable orders$/) do
  step 'I scroll to the end of the list'
  @contracts = \
    @current_inventory_pool
    .orders
    .where(state: [:submitted, :approved, :rejected])
    .joins(:reservations)
    .with_verifiable_user_and_model
    .with_some_line_not_in_any_contract
  @contracts.each {|c|
    expect(has_selector?("[data-type='order'][data-id='#{c.id}']")).to be true
  }
end

Then(/^these orders are ordered by creation date$/) do
  expect(all("[data-type='order']").map { |x| x['data-id'] })
    .to be == @contracts.order('created_at DESC').map(&:id)
end

Then(/^I see all pending verifiable orders$/) do
  step 'I scroll to the end of the list'
  @contracts = \
    @current_inventory_pool
    .orders
    .where(state: :submitted)
    .joins(:reservations)
    .with_verifiable_user_and_model
  @contracts.each {|c|
    expect(has_selector?("[data-type='order'][data-id='#{c.id}']")).to be true
  }
  @contract = @contracts.first
  @line_css =  "[data-type='order'][data-id='#{@contract.id}']"
end

Then(/^I see who placed this order on the order line and can view a popup with user details$/) do
  find(@line_css).has_text? @contract.user.name
  find("[data-firstname][data-id='#{@contract.user.id}']", match: :first).click
  expect(has_selector?('.tooltipster-base', text: @contract.user.name)).to be true
end

Then(/^I see the order's creation date on the order line$/) do
  extend ActionView::Helpers::DateHelper
  text = if @contract.created_at.today?
           _('Today')
         elsif @contract.created_at.to_date == Date.yesterday
           _('one day ago')
         else
           "#{time_ago_in_words(@contract.created_at)} ago"
         end
  find(@line_css, text: text)
end

Then(/^I see the number of items on the order line and can view a popup containing the items ordered$/) do
  sum_quantity = @contract.reservations.map(&:quantity).sum
  find("#{@line_css} [data-type='lines-cell']", text: "#{sum_quantity} #{n_("Item", "Items", sum_quantity)}")
    .click
  within find('.tooltipster-base') do
    @contract.models.each do |m|
      page.should have_content m.name
    end
  end
end

Then(/^I see the duration of the order on the order line$/) do
  expect(find(@line_css).has_content? "#{@contract.max_range} #{n_("day", "days", @contract.max_range)}").to be true
end

Then(/^I see the purpose on the order line$/) do
  expect(find(@line_css).has_content? @contract.purpose.to_s).to be true
end


Then(/^I can approve the order$/) do
  expect(find(@line_css).has_selector? '[data-order-approve]').to be true
end

Then(/^I can reject the order$/) do
  expect(find(@line_css).has_selector? '[data-order-reject]', visible: false).to be true
end

Then(/^I can edit the order$/) do
  expect(find(@line_css).has_selector? "[href*='#{manage_edit_order_path(@current_inventory_pool, @contract)}']", visible: false).to be true
end

Then(/^I cannot hand over orders$/) do
  expect(find(@line_css).has_no_selector?('a', text: _('Hand Over'))).to be true
end

Then(/^I see all verified and approved orders$/) do
  step 'I scroll to the end of the list'
  @contracts = \
    @current_inventory_pool
    .orders
    .where(state: :approved)
    .joins(:reservations)
    .with_verifiable_user_and_model
    .with_some_line_not_in_any_contract
  @contracts.each {|c|
    expect(has_selector?("[data-type='order'][data-id='#{c.id}']")).to be true
  }
  @contract = @contracts.first
  @line_css =  "[data-type='order'][data-id='#{@contract.id}']"
end

Then(/^I see the order's status on the order line$/) do
  find(@line_css, text: _(@contract.state.capitalize))
end

Then(/^I see all verifiable rejected orders$/) do
  step 'I scroll to the end of the list'
  @contracts = \
    @current_inventory_pool
    .orders
    .where(state: :rejected)
    .joins(:reservations)
    .with_verifiable_user_and_model
  @contracts.each {|c|
    expect(has_selector?("[data-type='order'][data-id='#{c.id}']")).to be true
  }
  @contract = @contracts.first
  @line_css =  "[data-type='order'][data-id='#{@contract.id}']"
end

When(/^I uncheck the filter "(.*?)"$/) do |filter|
  uncheck filter
end

Then(/^I see orders placed by users in groups requiring verification$/) do
  step 'I scroll to the end of the list'
  within '#contracts' do
    @contracts = \
      @current_inventory_pool
      .orders
      .joins(:reservations)
      .where(state: [:submitted, :approved, :rejected])
      .with_verifiable_user
      .with_some_line_not_in_any_contract
    @contracts.each do |contract|
      find(".line[data-type='order'][data-id='#{contract.id}']")
    end
  end
end

When(/^I edit an already approved order$/) do
  within '#contracts' do
    within all('.line[data-id]', minimum: 1).first do
      a = find('a', text: _('Edit'))
      @target_url = a[:href]
      a.click
    end
  end
end

Then(/^I am directed to the hand over view$/) do
  find('#hand-over-view')
  expect(current_url).to eq @target_url
end

But(/^I cannot hand over$/) do
  all("[data-line-type='item_line'] input[type='checkbox']:checked", minimum: 1).each &:click
  unless page.has_selector?('[data-hand-over-selection][disabled]')
    find('[data-hand-over-selection]').click
    find('#purpose').set Faker::Lorem.paragraph
    find('#note').set Faker::Lorem.paragraph
    find('button.green[data-hand-over]').click
    find('#error', text: _("You don't have permission to perform this action"))
  end
end

def hand_over_assign_or_add(s)
  find('#assign-or-add-input input').set s
  find('form#assign-or-add .row a:not(.red)', text: s).click
  find('#flash .notice', text: _('Added %s') % s)
end

Then(/^I can add models$/) do
  @model = if @current_user.access_right_for(@current_inventory_pool).role == :group_manager
             @current_inventory_pool.models.select {|m| m.availability_in(@current_inventory_pool).maximum_available_in_period_summed_for_groups(Date.today, Date.today) > 0 }
           else
             @current_inventory_pool.models
           end.detect {|m| m.items.where(inventory_pool_id: @current_inventory_pool, parent_id: nil).exists? }
  hand_over_assign_or_add @model.to_s
end

Then(/^I can add options$/) do
  option = @current_inventory_pool.options.first
  hand_over_assign_or_add option.to_s
end


But(/^I cannot assign items$/) do
  find("[data-line-type='item_line']", minimum: 1, match: :first)
  all("[data-line-type='item_line']", minimum: 1).each do |dom_line|
    within dom_line do
      find('input[data-assign-item]').click
      next unless has_selector?('li.ui-menu-item a')
      find('li.ui-menu-item a', match: :first).click
    end
    find("html").click
  end
  find('#flash .error', text: _("You don't have permission to perform this action"))
end

When(/^I am listing the (orders|contracts|visits)$/) do |arg1|
  case arg1
    when 'orders'
      visit manage_orders_path(@current_inventory_pool, state: [:approved, :submitted, :rejected])
    when 'contracts'
      visit manage_contracts_path(@current_inventory_pool, state: [:open, :closed])
    when 'visits'
      visit manage_inventory_pool_visits_path(@current_inventory_pool)
    else
      raise
  end
end

Given(/^(orders|contracts|visits) exist$/) do |arg1|
  @contracts = case arg1
                 when 'orders'
                   @current_inventory_pool.orders.where(state: [:submitted, :approved, :rejected])
                 when 'contracts'
                   @current_inventory_pool.contracts
                 when 'visits'
                   @current_inventory_pool.visits.where(is_approved: true)
                 else
                   raise
               end
  expect(@contracts.exists?).to be true
end

When(/^I search for an order which does not need verification using the user name$/) do
  @contract = \
    @current_inventory_pool
    .orders
    .joins(:reservations)
    .with_some_line_not_in_any_contract
    .no_verification_required
    .first
  @search_term = @contract.user.to_s
  within '#contracts-index-view' do
    step %Q(I search for "%s") % @search_term
  end
end

When(/^I search for an order which does not need verification using the purpose$/) do
  @contract = \
    @current_inventory_pool
    .orders
    .joins(:reservations)
    .with_some_line_not_in_any_contract
    .no_verification_required
    .first
  @search_term = @contract.purpose
  within '#contracts-index-view' do
    step %Q(I search for "%s") % @search_term
  end
end

When(/^I search( globally)? for (an order|a contract|a visit)( with its purpose)?$/) do |arg0, arg1, arg2|
  if arg1 == 'a contract'
    @contract = @current_inventory_pool.contracts.first
  elsif arg1 == 'an order'
    @contract = @current_inventory_pool.orders.joins(:reservations).with_some_line_not_in_any_contract.first
  elsif arg1 == 'a visit'
    @contract = @current_inventory_pool.visits.where(is_approved: true).first
  end
  @search_term = if arg2
                   @contract.purpose.split.sample.gsub(/^\W*/, '').gsub(/\W*$/, '')
                 else
                   @contract.user.to_s
                 end
  if arg0
    within '#topbar #search' do
      find('input#search_term').set @search_term
      find("button[type='submit']").click
    end
  else
    el = arg1 == 'a visit' ? '#visits-index-view' : '#contracts-index-view'
    within el do
      step %Q(I search for "%s") % @search_term
    end
  end
end

Then(/^all listed visits match the search term$/) do
  within '.list-of-lines' do
    find(".line[data-id='#{@contract.id}']")
    contract_ids = all('.line').map{|x| x['data-id'] }.sort
    matching_contracts_ids = \
      @contracts
      .filter2(search_term: @search_term)
      .map(&:id).map(&:to_s).sort
    expect(contract_ids).to eq matching_contracts_ids
  end
end

Then(/^all listed (?:orders|contracts) match the search term$/) do
  within '.list-of-lines' do
    find(".line[data-id='#{@contract.id}']")
    contract_ids = all('.line').map{|x| x['data-id'] }.sort
    matching_contracts_ids = \
      @contracts
      .no_verification_required
      .filter2({search_term: @search_term})
      .map(&:id).map(&:to_s).sort
    expect(contract_ids).to eq matching_contracts_ids
  end
end

When /^I uncheck the "No verification required" button$/ do
  selector = "#list-filters input[name='no_verification_required']"
  if has_selector?(selector)
    cb = find(selector)
    cb.click if cb.checked?
  end
end
