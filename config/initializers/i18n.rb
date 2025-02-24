I18n.available_locales = %i(de-CH en-GB en-US en es fr-CH gsw-CH)

Rails.application.config.after_initialize do
  I18n.default_locale = Language.default_language&.locale || "en-GB"
end
