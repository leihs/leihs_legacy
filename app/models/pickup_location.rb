class PickupLocation < ApplicationRecord
  belongs_to :inventory_pool
  has_many :reservations
end
