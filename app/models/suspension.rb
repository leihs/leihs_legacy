class Suspension < ApplicationRecord

  belongs_to :user
  belongs_to :inventory_pool
end
