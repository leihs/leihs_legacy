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

  deadline_soon_reservation = @current_user.reservations.signed.where('end_date > ?', Date.today).first
  pool = deadline_soon_reservation.inventory_pool
  visit = pool.visits.take_back.where(user_id: @current_user.id).where('date = ?', deadline_soon_reservation.end_date).first
  expect(visit).not_to be_nil

  # an unrelated, non-reminder email for the same user/pool must not be
  # picked up by the visits-list reminder scoping
  Email.create!(user_id: @current_user.id,
                to_address: @current_user.email,
                from_address: 'sender@example.com',
                subject: 'Unrelated approved mail',
                body: 'x',
                template: 'approved',
                source_pool_id: pool.id)

  # a reminder tied to a different visit for the same user/pool must not
  # leak into this visit's scoped reminder list either
  other_visit_email = Email.create!(user_id: @current_user.id,
                                    to_address: @current_user.email,
                                    from_address: 'sender@example.com',
                                    subject: 'Reminder for a different visit',
                                    body: 'x',
                                    template: 'deadline_soon_reminder',
                                    source_pool_id: pool.id)
  EmailVisit.create!(email: other_visit_email, visit_id: SecureRandom.uuid)

  scoped_emails = \
    visit.emails.where(user_id: @current_user.id, template: %w[reminder deadline_soon_reminder])

  expect(scoped_emails).not_to be_empty
  expect(scoped_emails.pluck(:template).uniq).to eq(['deadline_soon_reminder'])
  expect(scoped_emails.map(&:subject)).not_to include('Unrelated approved mail')
  expect(scoped_emails.map(&:subject)).not_to include('Reminder for a different visit')
  expect(scoped_emails.first.visits).to eq([visit])
end

Then(/^the day after the take back I receive a remember email$/) do
  expect(Email.count).to eq 0
  expect(Email.where(user_id: @current_user.id).empty?).to be true

  User.remind_and_suspend_all

  expect(Email.count).to be > 0
  expect(Email.where(user_id: @current_user.id).empty?).to be false

  expect(Email.all.detect {|x| x.to_address == @current_user.email }.nil?).to be false

  overdue_reservation = @current_user.reservations.signed.where('end_date < ?', Date.today).first
  pool = overdue_reservation.inventory_pool
  visit = pool.visits.take_back.where(user_id: @current_user.id).where('date = ?', overdue_reservation.end_date).first
  expect(visit).not_to be_nil

  # an unrelated, non-reminder email for the same user/pool must not be
  # picked up by the visits-list reminder scoping
  Email.create!(user_id: @current_user.id,
                to_address: @current_user.email,
                from_address: 'sender@example.com',
                subject: 'Unrelated approved mail',
                body: 'x',
                template: 'approved',
                source_pool_id: pool.id)

  # a reminder tied to a different visit for the same user/pool must not
  # leak into this visit's scoped reminder list either
  other_visit_email = Email.create!(user_id: @current_user.id,
                                    to_address: @current_user.email,
                                    from_address: 'sender@example.com',
                                    subject: 'Reminder for a different visit',
                                    body: 'x',
                                    template: 'reminder',
                                    source_pool_id: pool.id)
  EmailVisit.create!(email: other_visit_email, visit_id: SecureRandom.uuid)

  scoped_emails = \
    visit.emails.where(user_id: @current_user.id, template: %w[reminder deadline_soon_reminder])

  expect(scoped_emails).not_to be_empty
  expect(scoped_emails.pluck(:template).uniq).to eq(['reminder'])
  expect(scoped_emails.map(&:subject)).not_to include('Unrelated approved mail')
  expect(scoped_emails.map(&:subject)).not_to include('Reminder for a different visit')
  expect(scoped_emails.first.visits).to eq([visit])
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

Given(/^I have two overdue take backs with different end dates in the same pool$/) do
  first_reservation = @current_user.reservations.signed.first
  pool = first_reservation.inventory_pool

  item = FactoryBot.create(:item, owner: pool, inventory_pool: pool)
  contract = FactoryBot.create(:open_contract,
                               user: @current_user,
                               inventory_pool: pool,
                               items: [item],
                               start_date: Time.zone.today,
                               end_date: Time.zone.today + 3.days)
  second_reservation = contract.reservations.first

  @bundling_pool = pool
  Dataset.back_to_date(second_reservation.end_date + 1.day)

  overdue_reservations = @current_user.reservations.signed.where(inventory_pool_id: pool.id).where('end_date < ?', Date.today)
  expect(overdue_reservations.pluck(:end_date).uniq.length).to eq(2)
end

When(/^the overdue reminders are sent$/) do
  User.remind_and_suspend_all
end

Then(/^one reminder email is sent that is tied to both visits$/) do
  reminder_emails = Email.where(user_id: @current_user.id,
                                template: 'reminder',
                                source_pool_id: @bundling_pool.id)

  expect(reminder_emails.count).to eq(1)

  visits = reminder_emails.first.visits
  expect(visits.length).to eq(2)
  expect(visits.map(&:inventory_pool_id).uniq).to eq([@bundling_pool.id])
end

