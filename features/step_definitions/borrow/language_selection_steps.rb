# -*- encoding : utf-8 -*-

Given(/^I see the language list$/) do
  find("footer a[href*='locale']", match: :first)
end

When(/^I change the language to "(.*?)"$/) do |language|
  do_and_wait_for_page_change do
    find('footer a', text: language).click
  end
end

Then(/^the language is "(.*?)"$/) do |language|
  expect(@current_user.reload.language.name).to eq language
  find("footer a[href=''] strong", text: language)
end
