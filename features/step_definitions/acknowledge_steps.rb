# When "{string} clicks on 'acknowledge'" do | who |
#   get backend_inventory_pool_acknowledge_index_path(@inventory_pool)
#   @orders = assigns(:orders)
# #0402#
#   @response = response
# end

When "{string} chooses {string}'s order" do | who, name |
  order = @orders.detect { |o| o.user.login == name }
  get manage_edit_order_path(@inventory_pool, order)
  response.should render_template('backend/acknowledge/show')
  @order = assigns(:order)
  @response = response
end

When "{string} rejects order with reason {string}" do |who, reason|
  post "/manage/#{@inventory_pool.id}/orders/#{@order.id}/reject", {comment: reason}
  @order = assigns(:order)
  expect(@orders).not_to be_nil
  expect(@order).not_to be_nil
  @response = response
  expect(response.redirect_url).to eq "http://www.example.com/backend/inventory_pools/#{@inventory_pool.id}/acknowledge"
end

# When "{string} adds {string} item {string}" do |who, quantity, model|
#   model_id = Model.find_by_name(model).id
#   post add_line_backend_inventory_pool_acknowledge_path(@inventory_pool, @order, model_id: model_id, quantity: quantity)
#   @order = assigns(:order)
#   @order.reservations.each do | line |
#     expect(line.model).not_to be_nil
#   end
#   @response = response #new#
#   expect(@response.redirect_url).to include("backend/inventory_pools/#{@inventory_pool.id}/acknowledge/#{@order.id}")
# end


When "{string} adds a personal message: {string}" do |who, message|
  @comment = message
end

# When "{string} chooses 'swap' on order line {string}" do |who, model|
#   line = find_line(model)
#   get swap_model_line_backend_inventory_pool_acknowledge_path(@inventory_pool, @order, line_id: line.id)
#   @reservation_id = line.id
#   @response = response
# end

# When "{string} searches for {string}" do |who, model|
#   get manage_inventory_path(@inventory_pool, query: model, user_id: @order.user_id,
#                                         source_path: swap_model_line_backend_inventory_pool_acknowledge_path(@inventory_pool, @order, line_id: @reservation_id),
#                                         reservation_id: @reservation_id )
#   @models = assigns(:models)
#   expect(@models).not_to be_nil
# end

# When "{string} selects {string}" do |who, model|
#   model_id = Model.find_by_name(model).id
#   post swap_model_line_backend_inventory_pool_acknowledge_path(@inventory_pool, @order, line_id: @reservation_id, model_id: model_id)
#   @order = assigns(:order)
#   expect(@order).not_to be_nil
# end

Then /^(.*) see(s)? ([0-9]+) order(s?)$/ do | who, foo, size, s |
  find('.table-overview .fresh')
end

# NOTE this is not actually what he sees on the first page, but the total submitted orders
#Then /^(.*) sees ([0-9]+) order(s?)$/ do | who, size, s |
##old#0402  @orders.total_entries.should == size.to_i
#  When "#{who} clicks on 'acknowledge'" unless assigns(:orders)
#  assigns(:orders).total_entries.should == size.to_i
#end

#Then "{string}'s order is shown" do |name|
#  # TODO: we should be passing through the controller/view here!
#  user = User.find_by_login(name)
#  @order.user.login.should == user.login
#  @order.user.id.should == user.id
#end

Then 'Swap Item screen opens' do 
  expect(@response.redirect_url).to include("/backend/inventory_pools/#{@inventory_pool.id}/models?layout=modal&reservation_id=#{@reservation_id}&source_path=%2Fbackend%2Finventory_pools%2F#{@inventory_pool.id}%2Facknowledge%2F#{@order.id}%2Fswap_model_line%3Fline_id%3D#{@reservation_id}")
end

Then 'a choice of {string} item appears' do |size|
  expect(@models.size).to eq size.to_i
end

Then "{string} sees {string} items of model {string}" do |who, quantity, model|
  line = find_line(model)
  expect(line).not_to be_nil
  expect(line.quantity).to eq quantity.to_i
end

Then "all {string} order reservations are marked as invalid" do |what|
  # TODO: VERY ugly - we need have_tag "td.valid_false"
  expect(@response.body).to match /valid_false/
end

Then /the order should( not)? be approvable(.*)/ do |arg1, reason|
  if arg1
    expect(@response).to be_bad_request
    expect(@order).to be_nil
  else
    expect(@response).to be_ok

    expect(@order.approvable?).to be false
    @order.reservations.reload.each { |line| line.purpose = Purpose.first }
    expect(@order.approvable?).to be true
  end
end
