module Procurement
  class UserFilter < ApplicationRecord
    self.table_name = 'procurement_users_filters'

    belongs_to :user
  end
end
