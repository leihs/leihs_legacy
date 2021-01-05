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
  end

end
