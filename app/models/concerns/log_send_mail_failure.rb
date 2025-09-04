module LogSendMailFailure
  extend ActiveSupport::Concern

  included do
    def self.with_logging_send_mail_failure(recipient)
      begin
        yield
      rescue Exception => exception
        Rails.logger.error <<~MSG
          The following error happened while sending a notification email to user/pool
          #{recipient.id}: #{exception}
          That means that the user/pool probably did not get the mail
          and you need to contact the user/pool in a different way.
        MSG
      end
    end
  end
end
