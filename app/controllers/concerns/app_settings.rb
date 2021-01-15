module AppSettings
  extend ActiveSupport::Concern

  included do
    def app_settings
      @app_settings ||= Setting.first
    end
    helper_method :app_settings

    def system_and_security_settings
      @system_and_security_settings ||= SystemAndSecuritySetting.first
    end
    helper_method :system_and_security_settings

    def smtp_settings
      @smtp_settings ||= SmtpSetting.first
    end
    helper_method :smtp_settings
  end

end
