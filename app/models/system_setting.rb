class SystemSetting < ApplicationRecord
  audited

  def label_for_audits
    'SystemSettings'
  end

end
