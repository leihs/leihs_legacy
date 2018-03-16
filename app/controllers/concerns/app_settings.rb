module AppSettings
  extend ActiveSupport::Concern

  included do
    def app_settings
      @app_settings ||= OpenStruct.new(
        Setting.first.attributes.merge(SystemSetting.first.attributes))
    end
    helper_method :app_settings
  end
end
