# -*- encoding : utf-8 -*-

When(/^I start a handover in the manage area and remember the browser URL-path$/) do
  step 'I am doing a hand over'
  @remembered_path = page.current_url.split('/').drop(3).unshift('').join('/')
end

When(/^I am logged out$/) do
  UserSession.where(user: @current_user).destroy_all
end

When(/^I try to perform an action without being logged in$/) do
  find('#assign-or-add-input input').set 'A B'
  find('#assign-or-add-input input')
end

Then(/^I am redirected to the sign-in page$/) do
  wait_until { current_path == '/sign-in'}
  expect(current_path).to eq '/sign-in'
end

Then(/^The return-to parameter is filled out with the browser URL-path I remembered$/) do
  url = URI.parse(current_url)
  expect(Rack::Utils.parse_query(url.query)['return-to']).to eq @remembered_path
end
