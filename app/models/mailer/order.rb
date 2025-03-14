module Mailer::Order
  extend self

  def choose_language_for(order)
    I18n.locale =
      order.target_user.language.try(:locale) || I18n.default_locale
  end

  def approved(order, comment, sent_at = Time.zone.now)
    choose_language_for(order)

    name = 'approved'
    template = MailTemplate.get_template(order.inventory_pool,
                                         name,
                                         order.target_user.language)
    body =
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_order(order, comment))

    Email.create!(user_id: order.target_user.id,
                  to_address: order.target_user.email,
                  from_address: (order.inventory_pool.email || SmtpSetting.first.default_from_address),
                  subject: template.subject,
                  body: body)
  end

  def submitted(order, sent_at = Time.zone.now)
    choose_language_for(order)

    name = 'submitted'
    template = MailTemplate.get_template(order.inventory_pool,
                                         name,
                                         order.target_user.language)
    body = 
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_order(order, nil))

    Email.create!(user_id: order.target_user.id,
                  to_address: order.target_user.email,
                  from_address: (order.inventory_pool.email || SmtpSetting.first.default_from_address),
                  subject: template.subject,
                  body: body)
  end

  def received(order, sent_at = Time.zone.now)
    smtp_settings = SmtpSetting.first
    choose_language_for(order)

    name = 'received'
    template = MailTemplate.get_template(order.inventory_pool,
                                         name,
                                         order.target_user.language)
    body = 
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_order(order, nil))

    Email.create!(inventory_pool_id: order.inventory_pool.id,
                  to_address: (order.inventory_pool.email || smtp_settings.default_from_address),
                  from_address: (order.inventory_pool.email || smtp_settings.default_from_address),
                  subject: template.subject,
                  body: body)
  end

  def rejected(order, comment, sent_at = Time.zone.now)
    choose_language_for(order)

    name = 'rejected'
    template = MailTemplate.get_template(order.inventory_pool,
                                         name,
                                         order.target_user.language)
    body = 
      Liquid::Template
      .parse(template.body)
      .render(MailTemplate.liquid_variables_for_order(order, comment))

    Email.create!(user_id: order.target_user.id,
                  to_address: order.target_user.email,
                  from_address: (order.inventory_pool.email || SmtpSetting.first.default_from_address),
                  subject: template.subject,
                  body: body)
  end
end
