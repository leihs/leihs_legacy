# https://github.com/rubiety/nilify_blanks#global-usage

Rails.application.config.after_initialize do
  ApplicationRecord.nilify_blanks
end