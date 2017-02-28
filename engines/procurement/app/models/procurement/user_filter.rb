module Procurement
  class UserFilter < ActiveRecord::Base
    self.table_name = 'procurement_users_filters'

    belongs_to :user
  end
end
