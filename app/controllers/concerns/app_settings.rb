module AppSettings
  extend ActiveSupport::Concern

  included do
    def app_settings
      @app_settings ||= Setting.first
    end
    helper_method :app_settings
  end
end
