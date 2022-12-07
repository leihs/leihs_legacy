#
# Models in EntitlementGroups
#
Then 'that model should not be available in any other group'  do
  # FIXME how can be executed the next line ?? where is implemented the maximum method ??
  # quantities = @model.in(@inventory_pool).maximum_available_in_period_for_groups(@inventory_pool.entitlement_groups.where(['id != ?',@group]).pluck(:id))
  # quantities.values.reduce(:+).to_i.should == 0
end

Then /^(\w+) item(s?) of that model should be available in group '([^"]*)'( only)?$/ do |n, plural, group_name, exclusivity|
  n = to_number(n)
  @group = @inventory_pool.entitlement_groups.find_by_name(group_name)
  all_groups = [EntitlementGroup::GENERAL_GROUP_ID] + @inventory_pool.entitlement_group_ids
  quantities = Entitlement.hash_with_generals(@inventory_pool, @model)
  expect(quantities[@group.id].to_i).to eq to_number(n)

  all_groups.each do |group|
    expect(quantities[group].to_i).to eq 0 if (group ? group.name : 'General') != group_name
  end if exclusivity
end

Then 'that model should not be available in any group'  do
  expect(Entitlement.hash_with_generals(@inventory_pool, @model).reject { |group_id, num| group_id == EntitlementGroup::GENERAL_GROUP_ID }.size).to eq 0
end

# TODO: currently unused
# Given /^(\d+) items of that model in group "([^"]*)"$/ do |n, group_name|
#   step "#{n} items of model '#{@model.name}' exist"
#   step "I assign #{n} items to group \"#{group_name}\""
# end

#
# Items
#
When /^I add (\d+) item(s?) of that model$/ do |n, plural|
  step "#{n} items of model '#{@model.name}' exist"
end

When /^an item is assigned to group "([^"]*)"$/ do |to_group_name|
  step "I assign one item to group \"#{to_group_name}\""
end

When /^I assign (\w+) item(s?) to group "([^"]*)"$/ do |n, plural, to_group_name|
  n = to_number(n)
  to_group = @inventory_pool.entitlement_groups.find_by_name to_group_name
  FactoryBot.create(:entitlement,
                     model: @model,
                     entitlement_group: to_group,
                     quantity: n)
end

Then 'that model should not be available to anybody' do
  step '0 items of that model should be available to everybody'
end

Then '{int} items of that model should be available to everybody' do |n|
  User.where.not(login: nil).each do |user|
    step "#{n} items of that model should be available to \"#{user.login}\""
  end
end

Then /^(\w+) item(s?) of that model should be available to "([^"]*)"$/ do |n, plural, user|
  @user = User.find_by_login user
  expect(@model.availability_in(@inventory_pool.reload).maximum_available_in_period_for_groups(Date.today, Date.tomorrow, @user.entitlement_group_ids)).to eq n.to_i
end

#
# EntitlementGroups
#
Given /^a group '([^']*)'( exists)?$/ do |name,foo|
  step "I add a group called \"#{name}\""
end

When /^I add a group called "([^"]*)"$/ do |name|
  @inventory_pool.entitlement_groups.create(name: name)
end

# TODO: currently unused
Then /^he must be in group '(\w+)'( in inventory pool )?('[^']*')?$/ \
do |group, filler, inventory_pool|
  inventory_pools = []
  if inventory_pool
    inventory_pool.gsub!(/'/,'') # remove quotes
    inventory_pools << InventoryPool.find_by_name( inventory_pool )
  else
    inventory_pools = @user.inventory_pools
  end

  groups = inventory_pools.collect { |ip| ip.entitlement_groups.where(name: group).first }
  groups.each do |group|
    expect(group.users.find_by_id( @user.id )).not_to be_nil
  end
end

#
# Users
#
Given /^the customer "([^"]*)" is added to group "([^"]*)"$/ do |user, group|
  @user = User.find_by_login user
  @group = @inventory_pool.entitlement_groups.find_by_name(group)
  @group.users << @user
  @group.save!
end

Given /^a customer "([^"]*)" that belongs to group "([^"]*)"$/ do |user, group|
  step "a customer '#{user}' for inventory pool '#{@inventory_pool.name}'"
  step "the customer \"#{user}\" is added to group \"#{group}\""
end

When /^I lend (\w+) item(s?) of that model to "([^"]*)"$/ do |n, plural, user_login|
  user = User.find_by_login user_login
  purpose = 'this is the required purpose'
  order = FactoryBot.create(:order,
                             state: :approved,
                             user: user,
                             inventory_pool: @inventory_pool,
                             purpose: purpose)
  reservations = to_number(n).times.map do
    FactoryBot.create(:reservation,
                       status: :approved,
                       order: order,
                       inventory_pool: @inventory_pool,
                       user: user,
                       model: @model,
                       start_date: Date.today,
                       end_date: Date.tomorrow)
  end

  reservations.each do |cl|
    cl.update(item: cl.model.items.borrowable.in_stock.where(inventory_pool: cl.inventory_pool).sample )
  end

  contract = Contract.sign!(@user, @inventory_pool, user, reservations,
                            Faker::Lorem.sentence)
  expect(contract).to be_valid
end

When /^"([^"]*)" returns the item$/ do |user|
  @user = User.where(login: user).first
  cl = @user.reservations.last
  ApplicationRecord.transaction do
    cl.update(returned_date: Date.today)
    if cl.last_closed_reservation_of_contract?
      cl.contract.update(state: :closed)
    end
  end
  expect(cl.status).to be :closed
end
