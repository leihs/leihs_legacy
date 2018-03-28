class DisabledField < ApplicationRecord
  audited

  belongs_to :inventory_pool, inverse_of: :disabled_fields
  belongs_to :field, inverse_of: :disabled_fields

  def label_for_audits
    "#{field_id} - #{inventory_pool_id}"
  end

end
