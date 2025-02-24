class Holiday < ApplicationRecord
  belongs_to :inventory_pool, inverse_of: :holidays

  scope :future, -> { where(['end_date >= ?', Time.zone.today]) }
end
