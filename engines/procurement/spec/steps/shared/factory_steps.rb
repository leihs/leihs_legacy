# rubocop:disable Metrics/ModuleLength
module FactorySteps
  step 'a receiver exists' do
    FactoryGirl.create :user
  end

  step ':count main categories exist' do |count|
    n = case count
        when 'several'
            3
        else
            count.to_i
        end
    @main_categories = []
    n.times do
      @main_categories << FactoryGirl.create(:procurement_main_category)
    end
  end

  step 'several budget periods exist' do
    current_year = Time.zone.today.year
    @budget_periods = []
    (1..3).each do |num|
      @budget_periods << \
        FactoryGirl.create(
          :procurement_budget_period,
          name: current_year + num,
          inspection_start_date: Date.new(current_year + num, 1, rand(1..30)),
          end_date: Date.new(current_year + num, 2, 1)
        )
    end
  end

  step 'several requests created by myself exist' do
    budget_period = Procurement::BudgetPeriod.current
    h = {
      user: @current_user,
      budget_period: budget_period
    }
    h[:category] = @category if @category

    n = 5
    n.times do
      FactoryGirl.create :procurement_request, h
    end
    requests = Procurement::Request.where(user_id: @current_user,
                                          budget_period_id: budget_period)
    expect(requests.count).to eq n
  end

  step 'several categories exist' do
    10.times do
      FactoryGirl.create :procurement_category
    end
  end

  step 'several template articles in sub categories exist' do
    Procurement::Category.all.each do |category|
      @category = category
      step 'the category contains template articles'
    end
  end

  step ':nth request with following data exist' do |nth, table|
    @changes = {
      category: @category
    }
    table.hashes.each do |hash|
      hash['value'] = nil if hash['value'] == 'random'
      case hash['key']
      when 'budget period'
        @changes[:budget_period] = if hash['value'] == 'current'
                                     Procurement::BudgetPeriod.current
                                   else
                                     Procurement::BudgetPeriod.all.sample
                                   end
      when 'user'
        @changes[:user] = case hash['value']
                          when 'myself'
                            @current_user
                          else
                            @user = find_or_create_user(hash['value'], true)
                          end
      when 'requested amount'
        @changes[:requested_quantity] = \
          (hash['value'] || Faker::Number.number(2)).to_i
      when 'quantity'
        @changes[:quantity] = hash['value']
      when 'approved amount'
        @changes[:approved_quantity] = \
          (hash['value'] || Faker::Number.number(2)).to_i
      when 'inspection comment'
        @changes[:inspection_comment] = hash['value'] || Faker::Lorem.sentence
      when 'article or project'
        @changes[:article_name] = hash['value']
      when 'article nr. or producer nr.'
        @changes[:article_number] = hash['value']
      when 'supplier'
        @changes[:supplier_name] = hash['value']
      when 'name of receiver'
        @changes[:receiver] = hash['value']
      when 'replacement'
        @changes[:replacement] = (hash['value'] == 'Replacement' ? 1 : 0)
      when 'price'
        @changes[:price] = hash['value']
      when 'category'
        category = \
          if hash['value'] == 'inspected'
            Procurement::Category.all.detect do |category|
              not category.inspectable_by?(@current_user)
            end
          end
        @changes[:category] = category || hash['value']
      when 'building'
        @building = FactoryGirl.create(:building, name: hash['value'])
      when 'room'
        @changes[:room_id] = \
          FactoryGirl.create(:room, name: hash['value'], building: @building).id
      else
        @changes[hash['key'].parameterize.underscore.to_sym] = hash['value']
      end
    end
    request = FactoryGirl.create :procurement_request, @changes
    instance_variable_set("@request#{nth}", request)
  end

  step 'following requests exist for the current budget period' do |table|
    current_budget_period = Procurement::BudgetPeriod.current
    table.hashes.each do |value|
      n = value['quantity'].to_i
      user = case value['user']
             when 'myself' then @current_user
             else
                 find_or_create_user(value['user'], true)
             end
      h = {
        user: user,
        budget_period: current_budget_period
      }
      if value['category'] == 'inspected' or not @category.nil?
        h[:category] = @category || Procurement::Category.all.detect do |category|
          not category.inspectable_by?(@current_user)
        end
      end

      n.times do
        FactoryGirl.create :procurement_request, h
      end
      expect(current_budget_period.requests.where(user_id: user).count).to eq n
    end
  end

  step ':count sub categories exist' do |count|
    n = case count
        when 'several'
            3
        else
            count.to_i
        end
    @sub_categories = []
    n.times do
      @sub_categories << FactoryGirl.create(:procurement_category,
                                            main_category: @main_categories.sample)
    end
  end

  step 'the category contains template articles' do
    3.times do
      FactoryGirl.create :procurement_template, category: @category
    end
  end

  step 'there is a future budget period' do
    current_budget_period = Procurement::BudgetPeriod.current
    @counter = 1
    @future_budget_period = \
      begin
        FactoryGirl.create(:procurement_budget_period,
                           inspection_start_date: \
                             current_budget_period.end_date + @counter.month,
                           end_date: \
                             current_budget_period.end_date + \
                               (@counter + 1).months
                          )
      rescue => e
        if @counter <= 10
          @counter += 1
          retry
        else
          raise e
        end
      end
  end

  step 'a room :room for building :building exists' do |room, building|
    @room = FactoryGirl.create(
      :room,
      name: room,
      building: FactoryGirl.create(:building, name: building)
    )
  end
end
# rubocop:enable Metrics/ModuleLength
