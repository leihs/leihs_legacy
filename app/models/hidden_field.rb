class HiddenField < ApplicationRecord

  belongs_to :user, inverse_of: :hidden_fields

  def label_for_audits
    field_id
  end

end
