require_relative 'shared/common_steps'
require_relative 'shared/dataset_steps'
require_relative 'shared/factory_steps'
require_relative 'shared/file_upload_steps'
require_relative 'shared/filter_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_steps'
require_relative 'shared/request_steps'

steps_for :inspection do
  include CommonSteps
  include DatasetSteps
  include FactorySteps
  include FileUploadSteps
  include FilterSteps
  include NavigationSteps
  include PersonasSteps
  include RequestSteps

  step 'I can not move any request to the old budget period' do
    within("form[action='#{procurement.request_path(@request.id)}']") do
      link_on_dropdown(@past_budget_period.to_s, false)
    end
  end

  step 'I can not submit the data' do
    within("form[action='#{procurement.request_path(@request.id)}']") do
      find 'button[disabled]', text: _('Save'), match: :first
    end
  end

  step 'I press on the Userplus icon of a sub category I am inspecting' do
    step 'I expand all the sub categories'
    within '#filter_target' do
      within '.panel-success .panel-body' do
        within '.row .h4', text: @category.name do
          find('.fa-user-plus').click
        end
      end
    end
  end

  step 'I see all requests' do
    step 'I expand all the sub categories'
    within '#filter_target' do
      Procurement::Request.ids.each do |id|
        find "[data-request_id='#{id}']"
      end
    end
  end

  step 'I see only my own requests' do
    step 'I expand all the sub categories'
    within '#filter_target' do
      all('[data-request_id]', minimum: 1).each do |el|
        r = Procurement::Request.find(el['data-request_id'])
        expect(r.user_id).to eq @current_user.id
      end
    end
  end

  step 'I see the budget limit of each main category for each budget period' do
    @filter[:budget_period_ids].each do |id|
      budget_period = Procurement::BudgetPeriod.find id
      @filter[:category_ids].each do |id|
        main_category = Procurement::Category.find(id).main_category
        within '.panel-success > .panel-body .main_category',
               text: main_category.name do
          amount = main_category.budget_limits \
            .find_by(budget_period_id: budget_period) \
            .try(:amount) || 0
          find '.budget_limit', text: amount
        end
      end
    end
  end

  step 'I see the percentage of budget used ' \
       'compared to the budget limit of the main categories' do
    @main_categories.each_pair do |main_cat, cats|
      within '.panel-success > .panel-body .main_category',
             text: main_cat.name do
        limit = main_cat.budget_limits \
          .find_by(budget_period_id: Procurement::BudgetPeriod.current) \
          .try(:amount).to_i
        used = cats.map do |cat|
          @categories_totals[cat][:total]
        end.sum
        percentage = if limit > 0
                       used * 100 / limit
                     elsif used > 0
                       100
                     else
                       0
                     end
        find('.progress-radial',
             text: format('%d%', percentage))
      end
    end
  end

  step 'I see the total amount of each main category for each budget period' do
    @filter[:budget_period_ids].each do |id|
      budget_period = Procurement::BudgetPeriod.find id
      @filter[:category_ids].each do |id|
        main_category = Procurement::Category.find(id).main_category
        within '.panel-success > .panel-body .main_category',
               text: main_category.name do
          requests = @found_requests.select do |r|
            r.budget_period_id = budget_period.id \
              and main_category.category_ids.include? r.category_id
          end
          total = requests.map { |r| r.total_price(@current_user) }.sum.to_i
          find '.big_total_price', text: number_with_delimiter(total)
        end
      end
    end
  end

  step 'I see the total amount of each sub category for each budget period' do
    @found_requests = found_requests
    categories = Procurement::Category.find @filter[:category_ids]
    @categories_totals = {}
    categories.each do |category|
      parent_el = find('.row.main_category', text: category.main_category.name)
      parent_el.click if parent_el.has_no_selector? 'a[aria-expanded="true"]'

      @categories_totals[category] = {}
      within '.row', text: category.name do
        requests = @found_requests.select { |r| r.category_id = category.id }
        @categories_totals[category][:requests] = requests
        total = requests.map { |r| r.total_price(@current_user) }.sum.to_i
        @categories_totals[category][:total] = total
        find '.big_total_price', text: number_with_delimiter(total)
      end
    end
  end

  step 'I see the total of all budget limits of ' \
       'the shown main categories for each budget period' do
    @filter[:budget_period_ids].each do |id|
      budget_period = Procurement::BudgetPeriod.find id
      within '.panel > .panel-heading', text: budget_period.name do
        main_categories = @filter[:category_ids].map do |id|
          Procurement::Category.find(id).main_category
        end.uniq
        amount = main_categories.map do |mc|
          mc.budget_limits \
            .find_by(budget_period_id: budget_period) \
            .try(:amount) || 0
        end.sum
        find '.budget_limit', text: amount
      end
    end
  end

  step 'I see the total of all ordered amounts of a budget period' do
    total = Procurement::BudgetPeriod.current.requests
              .where(category_id: displayed_categories)
              .map { |r| r.total_price(@current_user) }.sum

    find '.panel-success > .panel-heading .label-primary.big_total_price',
         text: number_with_delimiter(total.to_i)
  end

  step 'I see the total of all ordered amounts of each group' do
    within '.panel-success .panel-body' do
      displayed_categories.each do |category|
        within '.row', text: category.name do
          total = Procurement::BudgetPeriod.current.requests
                      .where(category_id: category)
                      .map { |r| r.total_price(@current_user) }.sum
          find '.label-primary.big_total_price',
               text: number_with_delimiter(total.to_i)
        end
      end
    end
  end

  def my_categories
    Procurement::Category.all.select do |category|
      category.inspectable_by?(@current_user)
    end
  end

  step 'only categories having requests are shown' do
    expect(page).to have_no_selector \
      '.panel-body .label-primary.big_total_price', text: /^0$/
  end

  step 'only my categories are shown' do
    expect(displayed_categories).to eq my_categories
  end

  step 'several requests exist for my categories' do
    n = 3
    n.times do
      FactoryGirl.create :procurement_request,
                         category: my_categories.sample
    end
    expect(Procurement::Request.count).to eq n
  end

  step 'templates for my categories exist' do
    my_categories.each do |category|
      3.times do
        FactoryGirl.create :procurement_template, category: category
      end
    end
  end

  step 'the "Approved quantity" is copied to the field "Order quantity"' do
    expect(find("input[name*='[order_quantity]']").value).to eq \
      find("input[name*='[approved_quantity]']").value
  end

  step 'the current budget period is in inspection phase' do
    current_budget_period = Procurement::BudgetPeriod.current
    travel_to_date(current_budget_period.inspection_start_date + 1.day)
    expect(Time.zone.today).to be > current_budget_period.inspection_start_date
    expect(Time.zone.today).to be < current_budget_period.end_date
  end

  step 'the following fields are not editable' do |table|
    within('#filter_target') do
      table.raw.flatten.each do |value|
        within '.form-group', text: _(value), match: :prefer_exact do
          case value
          when 'Motivation'
            expect(page).to have_no_selector \
              "[name='requests[#{@request.id}][motivation]']"
            find '.col-xs-8', text: @request.motivation

          when 'Priority'
            expect(page).to have_no_selector \
              "[name='requests[#{@request.id}][priority]']"
            find '.col-xs-8', text: _(@request.priority.capitalize)
          when 'Requested quantity'
            expect(page).to have_no_selector \
              "[name='requests[#{@request.id}][requested_quantity]']"
            find '.col-xs-4', text: @request.requested_quantity
          else
            fail 'Unknown field!'
          end
        end
      end
    end
  end

  step 'the following information is deleted from the request' do |table|
    table.raw.flatten.each do |value|
      case value
      when 'Approved quantity'
        expect(@request.approved_quantity).to be_nil
      when 'Order quantity'
        expect(@request.order_quantity).to be_nil
      when 'Inspection comment'
        expect(@request.inspection_comment).to be_nil
      when "Inspector's priority"
        expect(@request.inspector_priority).to be == 'medium'
      else
        raise
      end
    end
  end

  step 'the list of requests is adjusted immediately' do
    step 'page has been loaded'
  end

  step 'the ordered amount and the price are multiplied and the result is shown' do
    total = find("input[name*='[price]']").value.to_i * \
              find("input[name*='[order_quantity]']").value.to_i
    expect(find('.label.label-primary.total_price').text).to eq currency(total)
  end

  step 'the total amount is calculated by adding all totals of the sub category' do
    @main_categories = @categories_totals.keys.group_by(&:main_category)
    @main_categories.each_pair do |main_cat, cats|
      within '.panel-success > .panel-body .main_category',
             text: main_cat.name do
        total = cats.map do |cat|
          @categories_totals[cat][:total]
        end.sum
        find '.big_total_price', text: number_with_delimiter(total)
      end
    end
  end

  step 'the total amount is calculated by adding the following amounts' do |table|
    @categories_totals.each_pair do |category, v|
      total = 0
      table.hashes.each do |hash|
        requests = v[:requests].select do |r|
          r.state(@current_user) == hash['state'].to_sym
        end
        total += requests.map do |r|
          (r.price * r.send("#{hash['quantity']}_quantity")).to_i
        end.sum
      end
      expect(total).to eq v[:total]
    end
  end

  step 'there is a budget period which has already ended' do
    current_budget_period = Procurement::BudgetPeriod.current
    @past_budget_period = \
      FactoryGirl.create \
        :procurement_budget_period,
        inspection_start_date: \
          current_budget_period.inspection_start_date - 2.months,
        end_date: current_budget_period.inspection_start_date - 1.month
  end

  step "the value of the field inspector's priority is set to the default value" do
    expect(@request.reload.inspector_priority).to be == 'medium'
  end

  step 'I delete the following fields' do |table|
    el1 = find('.panel-body')

    within el1 do
      find('.collapsed').click if el1.has_selector? '.collapsed'

      el2 = if @request
              ["[data-request_id='#{@request.id}']", visible: true]
            else
              [".request[data-request_id='new_request']"]
            end

      within(*el2) do
        table.raw.flatten.each do |value|
          case value
          when 'Price'
              find("input[name*='[price]']").set ''
          else
              fill_in _(value), with: ''
          end
        end
      end
    end
  end

  step 'I choose building :building' do |building|
    find('.form-group', text: _('Building'))
      .find('select')
      .select(building)
  end

  step 'I choose room :room' do |room|
    find('.form-group', text: _('Room'))
      .find('select')
      .select(room)
  end

  step 'I open this request' do
    step 'I navigate to the requests overview page'
    step 'I open the requests main category'
    step 'I open the requests category'
    step 'I click on the request line'
    step 'I see the request inline edit form' # to make sure its loaded
  end

  step 'I open the requests main category' do
    toggle_bootstrap_collapse(:open, @request.category.main_category.name)
  end

  step 'I open the requests category' do
    toggle_bootstrap_collapse(:open, @request.category.name)
  end

  step 'I try to close the requests main category' do
    toggle_bootstrap_collapse(
      :close, @request.category.main_category.name, check: false)
  end

  step 'I try to close the requests category' do
    toggle_bootstrap_collapse(:close, @request.category.name, check: false)
  end

  step 'I try to toggle a filter' do
    find('form#filter_panel').all('.form-group input[type="checkbox"]')
      .sample.click
  end

  step 'I see the request line' do
    line = find(".collapse.in > [data-request_id='#{@request.id}']")
    expect(line).to have_content @request.article_name
  end

  step 'I click on the request line' do
    line = find("[data-request_id='#{@request.id}']")
    line.click
  end

  step 'I see :nth request inline edit form' do |nth|
    fail unless nth == '' # only supports n=1, just for more explicit/readable step
    wait_until(10) do
      all(
        "form[action='#{procurement.request_path(@request.id)}'].in" \
        " [data-request_id='#{@request.id}']"
      ).first.present?
    end
  end

  step 'I save the inline form' do
    within("form[action='#{procurement.request_path(@request.id)}']") do
      click_on _('Save')
    end
  end

  step 'I see the updated request line' do
    line = find("[data-request_id='#{@request.id}']", visible: true)
    within(line) do
      expect(page).to have_content @changes[:article_name]
      expect(page).to have_content @changes[:user].to_s
    end
  end

  step 'the inline form has an error message :msg' do |msg|
    within("form[action='#{procurement.request_path(@request.id)}']") do
      flash_msg = find('.alert.alert-danger')
      expect(flash_msg.text).to eq msg
    end
  end

  step 'I try to open the 2. request' do
    req = @request2
    toggle_bootstrap_collapse(:open, req.category.main_category.name)
    toggle_bootstrap_collapse(:open, req.category.name)
    find("[data-request_id='#{req.id}']").click
  end

  step 'I change any text input field in the request form' do
    within("form[action='#{procurement.request_path(@request.id)}']") do
      all('input[type="text"], input[placeholder]').sample.set(Faker::Lorem.word)
    end
  end

  step ':boolean inspection comment templates exists' do |*args|
    should_exist, table = args # NOTE: variadic args…
    fail if should_exist and table.nil?
    settings = Procurement::Setting.find_or_create_by(id: 0)
    if should_exist
      settings.update_attributes!(inspection_comments: table.to_a)
      expect(settings.reload.inspection_comments).to eq table.to_a
    else
      expect(settings.inspection_comments).to eq []
    end
  end

  step 'I :boolean edit the inspector comment' do |can_see|
    expectation = can_see ? :have_selector : :have_no_selector
    selector = "textarea[name=\"requests[#{@request.id}][inspection_comment]\"]"
    expect(page).to(method(expectation).call(selector))
  end

  step 'I :boolean the comment template dropdown' do |can_see|
    expectation = can_see ? :have_selector : :have_no_selector
    selector = 'select#request_edit_select_inspection_comment_templates'
    expect(page).to(method(expectation).call(selector))
  end

  step 'I choose the comment template :string' do |string|
    select = find('select#request_edit_select_inspection_comment_templates')
    select.find('option', text: 'Too expensive').select_option
  end

  step 'the request has to following values saved in the database' do |table|
    old_upd = @request.updated_at
    wait_until { @request.reload.updated_at > old_upd }
    request = @request.reload.as_json
    table.to_a.drop(1).to_h.each do |attr, value|
      expect(request[attr]).to eq value
    end
  end

end
