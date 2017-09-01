# rubocop:disable Metrics/ModuleLength
placeholder :field_placeholder do
  match /.+/ do |field|
    case field
    when 'priority'
      _('Priority')
    when "inspector's priority"
      _("Inspector's priority")
    when 'replacement'
      format('%s / %s', _('Replacement'), _('New'))
    else
      raise
    end
  end
end

module CommonSteps

  def wait_until(wait_time = 60, &block)
    raise ArgumentError unless block_given?
    begin
      Timeout.timeout(wait_time) do
        until value = block.call
          sleep(1)
        end
        value
      end
    rescue Timeout::Error
      # rubocop:disable Style/RaiseArgs
      fail Timeout::Error.new(block.source)
      # rubocop:enable Style/RaiseArgs
    end
  end

  def toggle_bootstrap_collapse(state, label, check: true)
    fail unless [:open, :close].include? state
    toggler = find('[data-toggle="collapse"]', text: label)
    target = find('#' + toggler[:href].split('#').last, visible: nil)
    toggler.click
    return true unless check
    wait_until(15) do
      if state == :open
        target[:class].include? 'in'
      else
        toggler[:class].include? 'collapsed'
      end
    end
  end

  # rubocop:disable Lint/Debugger
  step 'I pry' do
    binding.pry
  end
  # rubocop:enable Lint/Debugger

  step 'I can not save' do
    step 'I click on save'
    step 'I do not see a success message'
  end

  step 'I can not save the request' do
    step 'I can not save'
  end

  step 'I click on save' do
    within 'article .page-content-wrapper' do
      el = all('button', text: _('Save'), minimum: 1).last
      el.click
    end
  end

  step 'I expand all the main categories' do
    all('.row.main_category', minimum: 1).each do |el|
      el.click if el.has_no_selector? 'a[aria-expanded="true"]'
      target_id = el.find('a')['href'].gsub(/.*#/, '')
      find ".panel-body .collapse##{target_id} .col-sm-8.h4"
    end
  end

  step 'I expand all the sub categories' do
    step 'page has been loaded'
    step 'I expand all the main categories'
    all('.panel-body .collapse .col-sm-8.h4', minimum: 1).each do |el|
      next if el.has_no_selector? 'i.fa-caret-right'
      if el.has_no_selector? '.toggler[aria-expanded="true"]'
        el.find('a.toggler', match: :first).click
      end
    end
  end

  step 'I press on the plus icon of a sub category' do
    @category ||= Procurement::Category.first
    step 'I deselect "Only categories with requests"'
    step 'I select all categories'
    step 'I expand all the sub categories'
    within '#filter_target' do
      within '.panel-success .panel-body' do
        within '.row .h4', text: @category.name do
          wait_until 3 do
            find('i.fa-plus-circle').click rescue nil
          end
        end
      end
    end
  end

  step 'I press on the plus icon of the current budget period' do
    within '#filter_target' do
      within '.panel-success > .panel-heading',
             text: Procurement::BudgetPeriod.current.name do
        find('i.fa-plus-circle').click
      end
    end
  end

  step 'I see the saved message' do
    expect(page).to have_content _('Saved')
  end

  step 'I :boolean a success message' do |boolean|
    if boolean
      Capybara.using_wait_time(8) do
        expect(page).to have_selector '.flash .alert-success'
      end
    else
      expect(page).to have_no_selector '.flash .alert-success'
    end
  end

  step 'I see an error message' do
    find '.flash .alert-danger', match: :first
  end

  step 'I see all main categories' do
    within '.panel-success .panel-body' do
      Procurement::MainCategory.all.each do |category|
        find '.row', text: category.name
      end
    end
  end

  step 'I see the amount of requests which are listed is :n' do |n|
    within '#filter_target' do
      find 'h4', text: /^#{n} #{_('Requests')}$/
    end
  end

  step 'I see the current budget period' do
    find '.panel-success > .panel-heading .h4',
         text: Procurement::BudgetPeriod.current.name
  end
  # alias
  step 'I see the budget period' do
    step 'I see the current budget period'
  end

  step 'I see the headers of the columns of the overview' do
    find '#column-titles'
  end

  step 'I see when the requesting phase of this budget period ends' do
    within '.panel-success > .panel-heading' do
      find '.row',
           text: _('requesting phase until %s') \
                  % I18n.l(Procurement::BudgetPeriod.current.inspection_start_date)
    end
  end

  step 'I see when the inspection phase of this budget period ends' do
    within '.panel-success > .panel-heading' do
      find '.row',
           text: _('inspection phase until %s') \
                  % I18n.l(Procurement::BudgetPeriod.current.end_date)
    end
  end

  step 'I press on a main category having sub categories' do
    @main_category = Procurement::Category.all.sample.main_category
    find('.panel-info > .panel-heading.collapsed h4',
         text: @main_category.name).click
  end

  step 'I press on the plus icon of one of its sub categories' do
    @category = @main_category.categories.first
    within '.panel-info', text: @main_category.name do
      within '.panel-default .panel-heading', text: @category.name do
        find('i.fa-plus-circle').click
      end
    end
  end

  step 'I want to create a new request' do
    step 'I navigate to the requests overview page'
    step 'I press on the plus icon of the current budget period'
    step 'I press on a main category having sub categories'
    step 'I press on the plus icon of one of its sub categories'
  end

  step 'page has been loaded' do
    # NOTE trick waiting page load
    if has_selector? '#filter_target.transparency'
      expect(page).to have_no_selector '#filter_target.transparency'
    end

    within '#filter_target' do
      expect(page).to have_no_selector '.spinner'
    end
  end

  step 'the changes are saved successfully to the database' do
    @request.reload
    @changes.each_pair do |k, v|
      expect(@request.send(k)).to eq v
    end
  end

  step 'the current date is after the budget period end date' do
    travel_to_date @request.budget_period.end_date + 1.day
    expect(Time.zone.today).to be > @request.budget_period.end_date
  end

  step 'the budget period has ended' do
    step 'the current date is after the budget period end date'
  end

  step 'the field :field is marked red' do |field|
    el = if @request
           ".request[data-request_id='#{@request.id}']"
         elsif has_selector? ".request[data-request_id='new_request']"
          ".request[data-request_id='new_request']"
         elsif has_selector? '#new_main_category.panel-default'
           '#new_main_category.panel-default'
         else
           all('form table tbody tr', minimum: 1).last
         end
    within el do
      case field
      when 'new/replacement'
          input_field = find("input[name*='[replacement]']", match: :first)
          label_field = \
            input_field.find(:xpath,
                             "./following-sibling::div[contains(@class, 'label')]")
      else
          input_field = case field
                        when 'requester name', 'name'
                            find("input[name*='[name]']")
                        when 'department'
                            find("input[name*='[department]']")
                        when 'organization'
                            find("input[name*='[organization]']")
                        when 'inspection start date'
                            find("input[name*='[inspection_start_date]']")
                        when 'end date'
                            find("input[name*='[end_date]']")
                        when 'article'
                            find("input[name*='[article_name]']")
                        when 'requested quantity'
                            find("input[name*='[requested_quantity]']")
                        when 'motivation'
                            find("textarea[name*='[motivation]']")
                        when 'inspection comment'
                            find("textarea[name*='[inspection_comment]']")
                        end
      end
      wait_until do
        input_field['required'] == 'true'
      end
      color = (label_field || input_field).native.css_value('background-color')
      expect(color).to eq 'rgba(242, 222, 222, 1)'
    end
  end

  def travel_to_date(datetime = nil)
    if datetime
      Timecop.travel datetime
    else
      Timecop.return
    end
  end

  def link_on_dropdown(link_string, present = true)
    el = find('.btn-group .fa-gear')
    btn = el.find(:xpath, './/parent::button')
    wrapper = btn.find(:xpath, './/parent::div')
    btn.click unless wrapper['class'] =~ /open/
    within wrapper do
      if present
        find('a', text: link_string)
      else
        expect(page).to have_no_selector('a', text: link_string)
      end
    end
  end

  def currency(amount)
    ActionController::Base.helpers.number_to_currency(
      amount,
      unit: Setting.local_currency_string,
      precision: 0)
  end

end
# rubocop:enable Metrics/ModuleLength
