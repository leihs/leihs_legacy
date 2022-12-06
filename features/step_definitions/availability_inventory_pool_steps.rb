Given 'this model has {int} item(s) in inventory pool {int}' do |number, ip|
  inventory_pool = InventoryPool.find_by_name(ip.to_s)
  number.times do | i |
    FactoryBot.create(:item, owner: inventory_pool, model: @model)
  end
  expect(inventory_pool.items.where(model_id: @model.id).count).to eq number
end

Then "the maximum number of available {string} for {string} is {int}" do |model, who, size|
  user = User.find_by_login(who)
  @model = Model.find_by_name(model)
  expect(user.items.where(model_id: @model.id).count).to eq size
end

Then 'he gets an empty result set' do
  expect(@models_json.empty?).to be true
end

Then "he sees the {string} model" do |model|
  m = Model.find_by_name(model)
  expect(@models_json.map{|x| x['label']}.include?(m.name)).to be true
end

Then /^this user has (\d+) unsubmitted reservations, which (\d+) are available$/ do |all_n, available_n|
  reservations = @user.reservations.unsubmitted
  expect(reservations.size).to eq all_n.to_i
  reservations = reservations.select &:available?
  expect(reservations.size).to eq available_n.to_i
end

Then(/^some order reservations were not created$/) do
  expect(@user.reservations.length).to eq @total_quantity
end
