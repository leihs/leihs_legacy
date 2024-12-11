Rails.application.config.after_initialize do
  if ApplicationRecord.connection.tables.include?('settings') and not Rails.env.test?
    if time_zone = Setting.first.try(:time_zone).presence
      Rails.configuration.time_zone = time_zone
      Time.zone_default = ActiveSupport::TimeZone.new(time_zone)
    end
  end
end
