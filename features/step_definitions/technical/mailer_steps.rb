When(/^the mail delivery method is set to "(.*?)"$/) do |method|
  ApplicationRecord.connection.execute <<-SQL
    UPDATE settings SET mail_delivery_method = '#{method}'
  SQL
  expect(Setting.first.mail_delivery_method).to eq method
end

Then(/^ActionMailer's delivery method is "(.*?)"$/) do |method|
  expect(ActionMailer::Base.delivery_method).to eq method.to_sym
end

When(/^the SMTP username is set to "(.*?)"$/) do |username|
  ApplicationRecord.connection.execute <<-SQL
    UPDATE settings SET smtp_username = '#{username}'
  SQL
  expect(Setting.first.smtp_username).to eq username
end

When(/^the SMTP password is set to "(.*?)"$/) do |password|
  ApplicationRecord.connection.execute <<-SQL
    UPDATE settings SET smtp_password = '#{password}'
  SQL
  expect(Setting.first.smtp_password).to eq password
end

Then(/^ActionMailer's SMTP username is "(.*?)"$/) do |username|
  expect(ActionMailer::Base.smtp_settings['user_name'.to_sym]).to eq username
end

Then(/^ActionMailer's SMTP password is "(.*?)"$/) do |password|
  expect(ActionMailer::Base.smtp_settings['password'.to_sym]).to eq password
end

Then(/^ActionMailer's SMTP username is nil$/) do
  expect(ActionMailer::Base.smtp_settings['user_name'.to_sym]).to eq nil
end

Then(/^ActionMailer's SMTP password is nil$/) do
  expect(ActionMailer::Base.smtp_settings['password'.to_sym]).to eq nil
end
