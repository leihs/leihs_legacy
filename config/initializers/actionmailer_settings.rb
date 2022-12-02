class ActionMailer::Base

  def self.smtp_settings
    default = {
      :address => "localhost",
      :port => 25,
      :domain => "localhost",
      :enable_starttls_auto => false,
      :openssl_verify_mode => 'none'
    }

    # If you don't check for the existence of a settings table, you will break
    # Rails initialization and so e.g. rake db:migrate no longer works. So
    # having no settings table will break initialization of the Rake task that
    # creates the settings table in the first place (!), creating a chicken and
    # egg problem.
    #
    # Additionally, we have to check for existance of each setting because the settings
    # table will be changed by migrations along the way, so the setting we expect to be
    # there might not actually exist while we are running the migration.
    if ApplicationRecord.connection.tables.include?("settings")
      app_settings = Setting.first
      smtp_settings = SmtpSetting.first
      begin
        result = {
          :address => smtp_settings.address,
          :port => smtp_settings.port,
          :domain => smtp_settings.domain,
          :enable_starttls_auto => smtp_settings.enable_starttls_auto,
          :openssl_verify_mode => smtp_settings.openssl_verify_mode,
          :authentication => smtp_settings.authentication_type
        }
      rescue
        logger.info("Could not configure ActionMailer because the database doesn't seem to be in the right shape for it. Check the settings table.")
        result = default
      end

      # Catch NameError and uninitialized constant if these settings aren't defined
      begin
        if (smtp_settings.username and smtp_settings.password) and (!smtp_settings.username.empty? and !smtp_settings.password.empty?)
          auth_settings = {
            :user_name => smtp_settings.username,
            :password => smtp_settings.password
          }
          result.merge!(auth_settings)
        end
      rescue
      end
    else
      result = default
    end
    return result
  end

  def self.file_settings
    { :location => Rails.root.join('tmp/mails') }
  end

  # NOTE: not used / used only in one test
  # def self.delivery_method
  #   begin
  #     if SmtpSetting.first.enabled
  #       :smtp
  #     else
  #       :test
  #     end
  #   rescue
  #     :smtp
  #   end
  # end

end
