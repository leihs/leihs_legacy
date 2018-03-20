module LogSendMailFailure
  def with_logging_send_mail_failure
    begin
      yield
    rescue Exception => exception
      # archive problem in the log, so the admin/developper
      # can look up what happened
      logger.error "#{exception}\n    #{exception.backtrace.join("\n    ")}"
      message = <<-MSG
        The following error happened while sending a notification email to
        #{target_user.email}: #{exception}.
        That means that the user probably did not get the mail
        and you need to contact him/her in a different way.
      MSG

      self.errors.add(:base, message)
    end
  end
end
