Given "a $role for inventory pool {string} logs in as {string}" do | role, ip_name, who |
  step "a #{role} '#{who}' for inventory pool '#{ip_name}'"
  step "I log in as '#{who}' with password 'pass'" # use default pw
  @last_manager_login_name = who
end

# This does NOT go through the UI. It simply logs in the user.
# for 99% of our Cucumber scenarios, we don't need the UI at all!
Given "a {string} for inventory pool {string} is logged in as {string}" do | role, ip_name, who |
  step "a #{role} '#{who}' for inventory pool '#{ip_name}'"
  step "I am logged in as '#{who}' with password 'foobar'"
  @last_manager_login_name = who
end

Given "I am logged in as {string} with password {string}" do |username, password|
  @current_user = User.where(login: username.downcase).first
  I18n.locale = if @current_user.language then @current_user.language.locale.to_sym else Language.default_language end
  @current_inventory_pool = @current_user.inventory_pools.managed.first
  case Capybara.current_driver
    when /firefox/
      visit '/'
      fill_in 'email', with: @current_user.email
      click_on _('Login')
    when :rack_test
      step "I log in as '%s' with password '%s'" % [username, password]
  end
end

Given "I log in as a {string} for inventory pool {string}{string}" do |role, ip_name,with_access_level|
  # use default user name
  step "a #{role} 'invman0' for inventory pool '#{ip_name}'#{with_access_level}"

  step "I log in as 'invman0' with password 'pass'" # use default pw
  @last_manager_login_name = 'invman0'
end

# This one 'really' goes through the auth process
When /^I log in as '([^']*)' with password '([^']*)'$/ do |username, password|
  @current_user = User.where(login: username.downcase).first
  @current_inventory_pool = @current_user.inventory_pools.managed.first
  visit "/"
  fill_in :email, with: @current_user.email
  click_on "Login"
end

Given /(his|her) password is '([^']*)'$/ do |foo,password|
  LeihsFactory.create_db_auth( login: @user.login, password: password)
end

When 'I log in as the admin' do
  step 'I am on the home page'
  step 'I make sure I am logged out'
  step 'I fill in "login_user" with "super_user_1"'
  step 'I fill in "login_password" with "pass"'
  step 'I press "Login"'
end

# It's possible that previous steps leave the running browser instance in a logged-in
# state, which confuses tests that rely on "When I log in as the admin".
When 'I make sure I am logged out' do
  step('I log out') if @current_user
end

When /^I am redirected to the "([^"]*)" section$/ do |section_name|
  case section_name
    when 'Admin'
      within '.topbar' do
        find('.navbar-right .dropdown-toggle', text: _(section_name))
      end
    else
      find('nav#topbar .topbar-navigation .active', match: :prefer_exact, text: _(section_name))
  end
end

Given(/^I am logged in as "(.*?)"$/) do |persona|
  step 'I make sure I am logged out'
  @current_user = User.where(login: persona.downcase).first
  fill_in :email, with: @current_user.email
  click_on "Login"
  I18n.locale = if @current_user.language then @current_user.language.locale.to_sym else Language.default_language end
  step 'I visit the homepage'
  expect(page).to have_content  @current_user.lastname
end
