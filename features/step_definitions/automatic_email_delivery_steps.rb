# -*- encoding : utf-8 -*-

Given(/^the system is configured for the mail delivery as test mode$/) do
  setting = Setting.first
  smtp_setting = SmtpSetting.first

  # Need to have these settings, otherwise we can't save. Ouch, coupling.
  if not setting
    setting = Setting.new
    setting[:local_currency_string] = 'GBP'
    setting[:email_signature] = 'Cheers,'
  end
  smtp_setting[:default_from_address] = 'sender@example.com'
  expect(setting.save).to be true
  expect(smtp_setting.save).to be true
end

Given(/^I have an overdue take back$/) do
  jump_to_date = @current_user.reservations.signed.first.end_date + 1.day
  Dataset.back_to_date(jump_to_date)
  overdue_lines = @current_user.reservations.signed.where('end_date < ?', Date.today)
  expect(overdue_lines.empty?).to be false
end

Given(/^I have a non overdue take back$/) do
  jump_to_date = @current_user.reservations.signed.first.end_date - 1.day
  Dataset.back_to_date(jump_to_date)
  deadline_soon_lines = @current_user.reservations.signed.where('end_date > ?', Date.today)
  expect(deadline_soon_lines.empty?).to be false
end

Then(/^the day before the take back I receive a deadline soon email$/) do
  expect(Email.count).to eq 0
  expect(Email.where(user_id: @current_user.id).empty?).to be true

  User.send_deadline_soon_reminder_to_everybody

  expect(Email.count).to be > 0
  expect(Email.where(user_id: @current_user.id).empty?).to be false

  expect(Email.all.detect {|x| x.to_address == @current_user.email}.nil?).to be false
end

Then(/^the day after the take back I receive a remember email$/) do
  expect(Email.count).to eq 0
  expect(Email.where(user_id: @current_user.id).empty?).to be true

  User.remind_and_suspend_all

  expect(Email.count).to be > 0
  expect(Email.where(user_id: @current_user.id).empty?).to be false

  expect(Email.all.detect {|x| x.to_address == @current_user.email }.nil?).to be false
end

Then(/^for each further day I receive an additional remember email$/) do
  Email.delete_all
  Dataset.back_to_date(Date.tomorrow)

  expect(Email.count).to eq 0

  User.remind_and_suspend_all

  expect(Email.count).to be > 0
  expect(Email.where(user_id: @current_user.id).empty?).to be false

  expect(Email.all.detect {|x| x.to_address == @current_user.email }.nil?).to be false
end

