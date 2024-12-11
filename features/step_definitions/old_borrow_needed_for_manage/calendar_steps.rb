When(/^I open the calendar of a model$/) do
  model = @current_user.models.borrowable.where('models.id' => @inventory_pool.models.select('models.id')).first
  visit borrow_model_path(model)
  find("[data-create-order-line][data-model-id='#{model.id}']").click
end

Given(/^the current inventory pool has reached maximum amount of visits$/) do
  if @current_inventory_pool.workday.reached_max_visits.empty?
    # NOTE set max visits to 1 for all days
    @current_inventory_pool.workday.update(max_visits: (0..6).inject({}) { |h, n| h[n] = 1; h })
  end
  expect(@current_inventory_pool.workday.reached_max_visits).not_to be_empty
end

When(/^I open the calendar of a model related to an inventory pool for which has reached maximum amount of visits$/) do
  @inventory_pool = @current_user.inventory_pools.detect { |ip| not ip.workday.reached_max_visits.empty? }
  @inventory_pool ||= @current_user.inventory_pools.detect do |ip|
    if ip.visits.where(is_approved: true).where('date >= ?', Date.today)
      # NOTE set max visits to 1 for all days
      ip.workday.update(max_visits: (0..6).inject({}) { |h, n| h[n] = 1; h })
      true
    else
      false
    end
  end
  step 'I open the calendar of a model'
end

When(/^I open the calendar of a model related to an inventory pool for which the number of days between order submission and hand over is defined as (\d+)$/) do |arg1|
  @inventory_pool = @current_user.inventory_pools.detect { |ip| ip.reservation_advance_days == arg1.to_i }
  @inventory_pool ||= begin
    ip = @current_user.inventory_pools.first
    ip.update(reservation_advance_days: arg1.to_i)
    ip
  end
  step 'I open the calendar of a model'
end

When(/^I select that inventory pool$/) do
  within '.modal' do
    within '#booking-calendar-inventory-pool' do
      find("option[data-id='#{@inventory_pool.id}']", text: @inventory_pool.name).click
    end
  end
end

Then(/^(the|no) availability number is shown (.*)$/) do |arg1, arg2|
  dates = case arg2
          when 'on this specific date'
            (@current_inventory_pool || @inventory_pool).workday.reached_max_visits
          when 'for today'
            Date.today
          when 'for tomorrow'
            Date.tomorrow
          when 'for the next open day after tomorrow'
            (@current_inventory_pool || @inventory_pool).next_open_date(Date.tomorrow + 1.day)
          else
            raise
          end
  within '.modal' do
    Array(dates).each do |date|
      while has_no_selector?(".fc-widget-content[data-date='#{date}']") do
        find('.fc-button-next').click
      end
      within ".fc-widget-content[data-date='#{date}']" do
        text = find('.fc-day-content').text
        case arg1
        when 'the'
          expect(text).not_to be_empty
        when 'no'
          expect(text).to be_empty
        else
          raise
        end
      end
    end
  end
end

When(/^I specify (.*) as (start|end) date$/) do |arg1, arg2|
  @date = case arg1
            when 'today'
              Date.today
            when 'tomorrow'
              Date.tomorrow
            when 'this date'
              (@current_inventory_pool || @inventory_pool).workday.reached_max_visits.sample
            else
              raise
          end
  step "I set the #{arg2} date in the calendar to '#{I18n::l(@date)}'"
end

Then(/^I receive an error message within the modal$/) do
  within '.modal #booking-calendar-errors' do
    find('.red')
  end
end

Then /^the start or end date of that line is changed$/ do
  @line.reload
  expect([@line.start_date, @line.end_date]).to include @date
end

Then /^the (start|end) date in the booking calendar becomes red and I see a (closed|not possible|too early) day warning?$/ do |arg1, arg2|
  date = Date.parse find(".modal #booking-calendar-#{arg1}-date").value
  within '.modal' do
    el = find(".fc-widget-content[data-date='#{date}']").native.style('background-color')
    # NOTE our red definition is #FF4C4D == rgba(255, 76, 77, 1)
    expect(el).to eq 'rgb(255, 76, 77)'

    s = case arg2
          when 'closed'
            _("Inventory pool is closed on #{arg1} date")
          when 'not possible'
            _("Booking is no longer possible on this #{arg1} date")
          when 'too early'
            _('No orders are possible on this start date')
        end
    find('.red', text: s)
  end
end
