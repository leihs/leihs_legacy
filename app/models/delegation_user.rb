class DelegationUser < ApplicationRecord
  self.table_name = 'delegations_users'

  belongs_to :delegation, class_name: 'User'
  belongs_to :user
end
