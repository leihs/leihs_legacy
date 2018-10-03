Then(/^the default (.*) exists in the database for a given (.*) and all languages$/) do |template_name, type|
  Language.all.each do |language|
    mt = MailTemplate.find_by(is_template_template: true,
                              type: type,
                              name: template_name,
                              language_id: language.id)
    expect(mt).to be
  end
  name_count = MailTemplate.select('DISTINCT(name)').count
  language_count = Language.count
  expect(MailTemplate.where(is_template_template: true).count).to be == (name_count * language_count)
end

When(/^I specify a mail template for the (.*) action (for the whole system|in the current inventory pool) for each active language$/) do |template_name, scope|
  case scope
    when 'for the whole system'
      visit '/admin/mail_templates'
      find('table tr', text: /^#{template_name}/).find('.btn', text: _('Edit')).click
    when 'in the current inventory pool'
      visit "/manage/#{@current_inventory_pool.id}/mail_templates"
      selector1 = '.list-of-lines .line-col.col2of5'
      selector2 = '.button'
      find(selector1, text: /^#{template_name}$/).find(:xpath, './..').find(selector2, text: _('Edit')).click
  end
  step 'I land on the mail templates edit page'
end

Then(/^the template (.*) is saved for the (whole system|current inventory pool) for each active language$/) do |template_name, scope|
  inventory_pool_id = case scope
                        when 'whole system'
                          nil
                        when 'current inventory pool'
                          @current_inventory_pool.id
                      end

  Language.active_languages.each do |language|
    mt = MailTemplate.find_by(inventory_pool_id: inventory_pool_id,
                              name: template_name.gsub(' ', '_'),
                              language: language,
                              format: 'text')
    expect(mt).not_to be_nil
  end
end

Given(/^I have a contract with deadline (yesterday|tomorrow)( for the inventory pool "(.*?)")?$/) do |day, arg1, inventory_pool_name|
  @visit = if arg1
             inventory_pool = InventoryPool.find_by(name: inventory_pool_name)
             @current_user.visits.where(inventory_pool_id: inventory_pool)
           else
             @current_user.visits
           end.take_back.first
  expect(@visit).not_to be_nil

  sign = case day
           when 'yesterday'
             :+
           when 'tomorrow'
             :-
         end

  Dataset.back_to_date(@visit.date.send(sign, 1.day))
end

When(/^the reminders are sent$/) do
  expect(ActionMailer::Base.deliveries.count).to eq 0
  User.send_deadline_soon_reminder_to_everybody
  User.remind_and_suspend_all
  expect(ActionMailer::Base.deliveries.count).to be > 0
end

Then(/^I receive an email formatted according to the (reminder|deadline_soon_reminder) mail template$/) do |template_name|
  language = Language.find_by(locale_name: @current_user.language.locale_name)

  sent_mails = ActionMailer::Base.deliveries.select { |m| m.to.include?(@current_user.email) and m.from.include?(@visit.inventory_pool.email) }
  sent_mails = sent_mails.select do |m|
    m.subject == case template_name
                   when 'reminder'
                     _('[leihs] Reminder')
                   when 'deadline_soon_reminder'
                     _('[leihs] Some items should be returned tomorrow')
                 end
  end
  expect(sent_mails.size).to eq 1
  sent_mail = sent_mails.first
  template = MailTemplate.find_by!(inventory_pool_id: @visit.inventory_pool_id,
                                   name: template_name,
                                   language: language,
                                   format: 'text')
  variables = MailTemplate.liquid_variables_for_user(@current_user, @visit.inventory_pool, @visit.reservations)
  expect(sent_mail.body.to_s).to eq Liquid::Template.parse(template.body).render(variables)
end

Given(/^the (reminder) mail template looks like$/) do |template_name, string|
  language = Language.find_by(locale_name: @current_user.language.locale_name)

  mt = MailTemplate.find_or_initialize_by(inventory_pool_id: @visit.inventory_pool_id,
                                          name: template_name.gsub(' ', '_'),
                                          language: language,
                                          format: 'text')
  mt.update_attributes(body: string)
end

def reset_language_for_current_user
  I18n.locale = @current_user.language.locale_name.to_sym
  expect(I18n.locale).to eq @current_user.language.locale_name.to_sym
end

def get_reminder_for_visit(visit)
  reset_language_for_current_user
  sent_mails = ActionMailer::Base.deliveries.select { |m| m.to.include?(@current_user.email) and m.from.include?(visit.inventory_pool.email) }
  sent_mails = sent_mails.select { |m| m.subject == _('[leihs] Reminder') }
  expect(sent_mails.size).to eq 1
  sent_mails.first
end

Then(/^the mail body looks like$/) do |string|
  sent_mail = get_reminder_for_visit(@visit)
  expect(sent_mail.body.to_s).to eq string
end

When(/^my language is set to "(.*?)"$/) do |locale_name|
  language = Language.find_by(locale_name: locale_name)
  @current_user.update_attributes(language: language)
  expect(@current_user.reload.language.locale_name).to eq locale_name
end

When(/^one of my submitted orders to an inventory pool without custom approved mail templates get approved$/) do
  expect(ActionMailer::Base.deliveries.count).to eq 0
  @contract = @current_user.orders.submitted.detect { |c| c.approvable? }
  @contract.approve(Faker::Lorem.sentence)
  expect(ActionMailer::Base.deliveries.count).to be > 0
end

Then(/^I receive an approved mail based on the system\-wide template for the language "(.*?)"$/) do |locale_name|
  language = Language.find_by(locale_name: locale_name)

  sent_mails = ActionMailer::Base.deliveries.select { |m| m.to.include?(@current_user.email) and m.from.include?(@contract.inventory_pool.email) }
  sent_mails = sent_mails.select { |m| m.subject == _('[leihs] Reservation Confirmation') }
  expect(sent_mails.size).to eq 1
  sent_mail = sent_mails.first

  template = MailTemplate.find_by(inventory_pool_id: nil,
                                  name: 'approved',
                                  language: language,
                                  format: 'text').body

  variables = MailTemplate.liquid_variables_for_order(@contract)
  expect(sent_mail.body.to_s).to eq Liquid::Template.parse(template).render(variables)
end

Then(/^I receive a reminder in "(.*?)"$/) do |locale_name|
  variables = MailTemplate.liquid_variables_for_user(@current_user, @visit.inventory_pool, @visit.reservations)
  language = Language.find_by!(locale_name: locale_name)
  template = MailTemplate.find_by!(inventory_pool_id: @visit.inventory_pool_id,
                                   name: :reminder,
                                   language: language,
                                   format: 'text')
  string = Liquid::Template.parse(template.body).render(variables)
  sent_mail = get_reminder_for_visit(@visit)
  expect(sent_mail.body.to_s).to eq string
end

When(/^I edit the (reminder) with the "(.*?)" template in "(.*?)"$/) do |template_name, body, locale_name|
  selector = @current_inventory_pool ? '.row.margin-vertical-s' : '.form-group'
  find(selector, text: locale_name).find("textarea[name='mail_templates[][body]']").set body
end

Then(/^I land on the mail templates edit page$/) do
  find("form button[type='submit']", text: _('Save %s') % _('Mail Templates'))
  Language.active_languages.each do |language|
    find("input[name='mail_templates[][language]'][type='hidden'][value='#{language.locale_name}']", visible: false)
  end
end

Then(/^the failing (reminder) mail template in "(.*?)" is highlighted in red$/) do |template_name, locale_name|
  selector = @current_inventory_pool ? '.row.margin-vertical-s' : '.form-group'
  expect(find(selector, text: locale_name).native.css_value('background-color')).to eq 'rgba(255, 176, 176, 1)'
end

Then(/^the failing (reminder) mail template in "(.*?)" is not persisted with the "(.*?)" template$/) do |template_name, locale_name, body|
  language = Language.find_by(locale_name: locale_name)
  template = MailTemplate.find_or_initialize_by(inventory_pool_id: @current_inventory_pool.try(:id),
                                                name: template_name.gsub(' ', '_'),
                                                language: language,
                                                format: 'text')
  expect(template.body).not_to eq body
end

When(/^I navigate to the mail templates list in the current inventory pool$/) do
  visit "/manage/#{@current_inventory_pool.id}/mail_templates"
end

Then(/^I am redirected to the login page$/) do
  find('#login-form')
end

Then(/^I see a list of mail templates$/) do
  find('nav .active', text: _('Mail Templates'))
  find('.list-of-lines')
end

Then(/^I don't see a list of mail templates$/) do
  expect(page).not_to have_content _('Mail Templates')
  expect(first('.list-of-lines')).not_to be
end

Then(/^I see a notification that I don't have sufficient permissions$/) do
  el = find('#flash')
  expect(el).to have_content _("You don't have permission to perform this action")
end
