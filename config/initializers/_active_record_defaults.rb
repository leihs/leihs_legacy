# The following config does not work!
# Rails.application.config.active_record.belongs_to_required_by_default = false
class ActiveRecord::Base
  @@belongs_to_required_by_default = false
end
