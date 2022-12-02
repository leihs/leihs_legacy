Given(/^I log out$/) do
  toggle = first('.topbar .dropdown-holder', text: @current_user.try(:lastname))
  toggle ||= first('.topbar .dropdown', text: @current_user.try(:lastname))
  if toggle
    toggle.click
    sign_out_button = first(".topbar form[action='/sign-out'] button",
                            visible: :all)
    sign_out_button.click
    find('#flash')
  else
    visit root_path
  end
end

When(/^I visit the homepage$/) do
  visit root_path
end

When(/^I login as "(.*?)" via web interface$/) do |persona|
  @current_user = User.where(login: persona.downcase).first
  I18n.locale = if @current_user.language then
                  @current_user.language.locale.to_sym
                else
                  Language.default_language
                end
  step 'I visit the homepage'
  fill_in 'email', with: @current_user.email
  click_on _('Login')
end

When(/^I login as "(.*?)" via web interface using keyboard$/) do |persona|
  @current_user = User.where(login: persona.downcase).first
  I18n.locale = if @current_user.language then
                  @current_user.language.locale.to_sym
                else
                  Language.default_language
                end
  step 'I visit the homepage'
  find("a[href='#{login_path}']", match: :first).click
  fill_in 'username', with: persona.downcase
  sleep 0.2
  pw_field = find('[name="login[password]"]')
  pw_field.native.send_keys('passw')
  sleep 0.2 # must be larger than BarcodeScanner delay (100ms)!
  pw_field.native.send_keys('ord', :enter)
end

Then(/^I am logged in$/) do
  expect(has_content?(@current_user.short_name)).to be true
end

Given(/^my authentication system is "(.*?)"$/) do |arg1|
  expect(@current_user.authentication_system.class_name).to eq arg1
end

When(/^I hover over my name$/) do
  find("nav.topbar ul.topbar-navigation .topbar-item", text: @current_user.short_name).hover
end

Then(/^I get to the "(.*?)" page$/) do |arg1|
  case arg1
    when 'User Data'
      expect(current_path).to eq borrow_current_user_path
    else
      raise
  end
end

When(/^I change my password$/) do
  @new_password = Faker::Internet.password(min_length: 6)
  find('.row', match: :prefer_exact, text: _('Password')).find("input[name='db_auth[password]']").set @new_password
  find('.row', match: :prefer_exact, text: _('Password Confirmation')).find("input[name='db_auth[password_confirmation]']").set @new_password
  find(".row button[type='submit']", text: _('Save')).click
  step %Q(I get to the "User Data" page)
end

Then(/^my password is changed$/) do
  find('#flash .success', text: _('Password changed'))
  dbauth = DatabaseAuthentication.authenticate(@current_user.login, @new_password)
  expect(dbauth).not_to be_nil
  expect(dbauth.user).to eq @current_user
end
