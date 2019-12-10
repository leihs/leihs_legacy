class Suspension < ApplicationRecord
  audited

  belongs_to :user
  belongs_to :inventory_pool
end
