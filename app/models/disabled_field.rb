class DisabledField < ApplicationRecord

  belongs_to :inventory_pool, inverse_of: :disabled_fields
  belongs_to :field, inverse_of: :disabled_fields

end
