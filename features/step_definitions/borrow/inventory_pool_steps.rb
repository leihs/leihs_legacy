# -*- encoding : utf-8 -*-

def user_by_login(login)
  User.find_by(login: login)
end

def create_pool_with_contract(login, name, description)
  user = user_by_login(login)
  ip1 = FactoryGirl.create(:inventory_pool, name: name, description: description)
  FactoryGirl.create(:access_right, user: user, inventory_pool: ip1, role: :customer)
  i1 = FactoryGirl.create(:item, inventory_pool: ip1, is_borrowable: 1)
  FactoryGirl.create(:open_contract, user: user, inventory_pool: ip1, items: [i1])
end

def create_pool_with_borrowable_item(login, name, description)
  ip3 = FactoryGirl.create(:inventory_pool, name: name, description: description)
  FactoryGirl.create(:access_right, user: user_by_login(login), inventory_pool: ip3, role: :customer)
  FactoryGirl.create(:item, inventory_pool: ip3, is_borrowable: 1)
end

def create_pool_with_neither(login, name, description)
  ip2 = FactoryGirl.create(:inventory_pool, name: name, description: description)
  FactoryGirl.create(:access_right, user: user_by_login(login), inventory_pool: ip2, role: :customer)
  FactoryGirl.create(:item, inventory_pool: ip2, is_borrowable: 0)
end

def create_a_user(login)
  FactoryGirl.create(:user, login: login)
end

def do_logout
  visit logout_path
  find('#flash')
end

def do_login(login, password)
  do_logout

  click_on _('Login')
  fill_in _('Username'), with: login
  fill_in _('Password'), with: password
  click_on _('Login')
end

def open_inventory_pool_list
  visit borrow_root_path
  find("a[href='#{borrow_inventory_pools_path}']", match: :first).click
end

def parse_names_from_list
  all('.row .padding-inset-l > .row > h2.padding-bottom-s').map(&:text)
end

def parse_descriptions_from_list
  all('.row .padding-inset-l > .row > p.pre').map(&:text)
end

def check_inventory_pool_names(expected)
  expect(parse_names_from_list).to eq(expected)
end

def check_inventory_pool_descriptions(expected)
  expect(parse_descriptions_from_list).to eq(expected)
end

def execute_scenario
  create_a_user('User1')
  create_pool_with_borrowable_item('User1', 'Ip3', 'Description3')
  create_pool_with_contract('User1', 'Ip1', 'Description1')
  create_pool_with_neither('User1', 'Ip2', 'Description2')
  do_login('User1', 'password') # Default password in user_factory.rb
  open_inventory_pool_list
  check_inventory_pool_names(['Ip1', 'Ip3'])
  check_inventory_pool_descriptions(['Description1', 'Description3'])
end

Then(/^I see the inventory pools which have borrowable items or a contract for my user exists$/) do
  execute_scenario
end
