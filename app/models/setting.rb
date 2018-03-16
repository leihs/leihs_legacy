class Setting < ApplicationRecord
  audited

  def label_for_audits
    'Settings'
  end

end
