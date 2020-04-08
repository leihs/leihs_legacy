class DirectAccessRight < ApplicationRecord

  self.table_name = :direct_access_rights

  belongs_to :user
  belongs_to :inventory_pool

end
