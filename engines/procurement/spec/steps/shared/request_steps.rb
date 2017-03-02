# rubocop:disable Metrics/ModuleLength
module RequestSteps
  step 'for each request I see the following information' do |table|
    step 'I expand all the sub categories'
    elements = all('[data-request_id]', minimum: 1)
    expect(elements).not_to be_empty
    elements.each do |element|
      request = Procurement::Request.find element['data-request_id']
      within element do
        table.raw.flatten.each do |value|
          case value
          when 'article name'
              find '.col-sm-2', text: request.article_name
          when 'name of the requester'
              find '.col-sm-2', text: request.user.to_s
          when 'department'
              find '.col-sm-2', text: request.organization.parent.to_s
          when 'organisation'
              find '.col-sm-2', text: request.organization.to_s
          when 'price'
              find '.col-sm-1 .total_price', text: request.price.to_i
          when 'requested amount'
              wait_until(5) { first '.col-sm-2.quantities div' }
              within first('.col-sm-2.quantities div') do
                expect(page).to have_content request.requested_quantity
              end
          when 'approved amount'
              wait_until(5) { all('.col-sm-2.quantities div')[1] }
              within all('.col-sm-2.quantities div')[1] do
                expect(page).to have_content request.approved_quantity
              end
          when 'order amount'
              wait_until(5) { all('.col-sm-2.quantities div')[2] }
              within all('.col-sm-2.quantities div')[2] do
                expect(page).to have_content request.order_quantity
              end
          when 'total amount'
              find '.col-sm-1 .total_price',
                   text: request.total_price(@current_user).to_i
          when 'priority'
              find '.col-sm-1', text: _(request.priority.capitalize)
          when 'state'
              state = request.state(@current_user)
              find '.col-sm-1', text: _(state.to_s.humanize)
          else
              raise
          end
        end
      end
    end
  end

  step 'I choose the following :field_placeholder value' do |label, table|
    el = if @template
           ".request[data-template_id='#{@template.id}']"
         else
           '.request[data-request_id="new_request"]'
         end
    within el do
      within '.form-group', text: label, match: :prefer_exact do
        table.raw.flatten.each do |value|
          choose _(value)
        end
      end
    end
  end

  step 'I can choose the following :field values' do |field, table|
    step "I choose the following #{field} value", table
  end

  step 'I choose the name of a receiver' do
    @receiver = User.not_as_delegations.where.not(id: @current_user).sample
    fill_in _('Name of receiver'), with: @receiver.name
  end

  step 'I choose the point of delivery' do
    @location = Location.all.sample
    fill_in _('Point of Delivery'), with: @location.to_s
  end

  step 'I fill in all mandatory information' do
    @changes = {}
    request_el = if @template
                   ".request[data-template_id='#{@template.id}']"
                 else
                   ".request[data-request_id='new_request']"
                 end
    within request_el do
      selector = if has_selector? '[data-to_be_required]:invalid'
                   '[data-to_be_required]:invalid'
                 else
                   '[data-to_be_required]'
                 end
      all(selector, minimum: 1).each do |el|
        key = el['name'].match(/.*\[(.*)\]\[(.*)\]/)[2]

        case key
        when 'requested_quantity'
            el.set v = Faker::Number.number(2).to_i
        when 'replacement'
            find("input[name*='[replacement]'][value='#{v = 1}']").click
        else
            el.set v = Faker::Lorem.sentence
        end

        @changes[key.to_sym] = v
      end
    end
  end

  step 'I move a request to the future budget period' do
    within all('.request', minimum: 1).last do
      @request = Procurement::Request.find current_scope['data-request_id']
      wait_until 3 do
        link_on_dropdown(@future_budget_period.to_s).click rescue nil
      end
    end

    @changes = {
      budget_period_id: @future_budget_period.id
    }
  end

  step 'I move a request to the other category' do
    within all('.request', minimum: 1).last do
      @request = Procurement::Request.find current_scope['data-request_id']
      categories = Procurement::Category.where.not(id: @request.category_id)

      @other_category = if @not_inspected_category
                          categories.detect do |category|
                            not category.inspectable_by?(@current_user)
                          end
                        else
                          categories.first
                        end

      wait_until 3 do
        link_on_dropdown(@other_category.name).click rescue nil
      end
    end

    @changes = {
      category_id: @other_category.id
    }
  end

  step 'I move a request to the other category where I am not inspector' do
    @not_inspected_category = true
    step 'I move a request to the other category'
  end

  step 'I see the amount of requests listed' do
    within '#filter_target' do
      find 'h4', text: /^\d #{_('Requests')}$/
    end
  end

  step 'I fill in the following fields' do |table|
    @changes ||= {}

    el = if @template
           'article .page-content-wrapper ' \
           ".request[data-template_id='#{@template.id}']"
         else
           'article .page-content-wrapper'
         end
    table.hashes.each do |hash|
      within el do
        hash['value'] = nil if hash['value'] == 'random'
        case hash['key']
        when 'Price'
          v = (hash['value'] || Faker::Number.number(4)).to_i
          find("input[name*='[price]']").set v
        when /quantity/
          v = (hash['value'] || Faker::Number.number(2)).to_i
          fill_in _(hash['key']), with: v
        when 'Replacement / New'
          v = (hash['value'] == 'Replacement' ? 1 : 0) || [0, 1].sample
          find("input[name*='[replacement]'][value='#{v}']").click
        else
          v = hash['value'] || Faker::Lorem.sentence
          fill_in _(hash['key']), with: v
        end
        @changes[mapped_key(hash['key'])] = v
      end

      # NOTE trigger change event
      find('body').native.send_keys(:tab) # find('body').click
    end
  end

  step 'the request with all given information ' \
       'was :updated_or_created successfully in the database' do |_|
    user = @user || @current_user
    if price = @changes.delete(:price)
      @changes[:price_cents] = price * 100
    end
    expect(@category.requests.where(user_id: user).find_by(@changes)).to be
  end

  step 'the status is set to :state' do |state|
    within '.form-group', text: _('State') do
      find '.label', text: _(state)
    end
  end

  def mapped_key(from)
    case from
    when 'Article or Project'
      :article_name
    when 'Article nr. or Producer nr.'
      :article_number
    when 'Replacement / New'
      :replacement
    when 'Supplier'
      :supplier_name
    when 'Name of receiver'
      :receiver
    when 'Point of Delivery'
      :location_name
    else
      from.parameterize.underscore.to_sym
    end
  end

  def number_with_delimiter(n)
    ActionController::Base.helpers.number_with_delimiter(n)
  end

  def displayed_categories
    Procurement::Category.where(name: all('div.row .h4', minimum: 0).map(&:text))
  end
end
# rubocop:enable Metrics/ModuleLength
