module Mailer::User
  extend self

  def choose_language_for(user)
    language = \
      user.language.try(:locale) \
        || Language.default_language.try(:locale)
    I18n.locale = language || I18n.default_locale
  end

  def remind(user, inventory_pool, reservations)
    choose_language_for(user)

    name = 'reminder'
    template = MailTemplate.get_template(inventory_pool,
                                         name,
                                         user.language)
    body =
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_user(user,
                                                     inventory_pool,
                                                     reservations))

    user.email_addresses.each do |user_email|
      Email.create!(user_id: user.id,
                    to_address: user_email,
                    from_address: (inventory_pool.email || SmtpSetting.first.default_from_address),
                    subject: template.subject,
                    body: body)
    end
  end

  def deadline_soon_reminder(user, inventory_pool, reservations)
    choose_language_for(user)

    name = 'deadline_soon_reminder'
    template = MailTemplate.get_template(inventory_pool,
                                         name,
                                         user.language)
    body = 
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_user(user,
                                                     inventory_pool,
                                                     reservations))

    user.email_addresses.each do |user_email|
      Email.create!(user_id: user.id,
                    to_address: user_email,
                    from_address: (inventory_pool.email || Setting.first.default_from_address),
                    subject: template.subject,
                    body: body)
    end
  end
end
