module Mailer
  include LogSendMailFailure

  def self.send_mail
    SmtpSetting.first.enabled
  end

  def self.order_approved(order, comment)
    if send_mail
      with_logging_send_mail_failure(order.target_user) do
        Mailer::Order.approved(order, comment)
      end
    end
  end

  def self.order_rejected(order, comment)
    if send_mail
      with_logging_send_mail_failure(order.target_user) do
        Mailer::Order.rejected(order, comment)
      end
    end
  end

  def self.deadline_soon_reminder(user, reservations)
    if send_mail
      reservations.map(&:inventory_pool).uniq.each do |inventory_pool|
        with_logging_send_mail_failure(user) do
          Mailer::User.deadline_soon_reminder(user,
                                              inventory_pool,
                                              reservations)
        end
      end
    end
  end

  def self.remind_user(user, reservations)
    if send_mail
      reservations.map(&:inventory_pool).uniq.each do |inventory_pool|
        with_logging_send_mail_failure(user) do
          Mailer::User.remind(user, inventory_pool, reservations)
        end
      end
    end
  end

  def self.user_email(user, from, to, subject, body)
    if send_mail
      with_logging_send_mail_failure(user) do
        Mailer::User.email(user, from, to, subject, body)
      end
    end
  end

end
