class DelegationUser < ApplicationRecord
  self.table_name = 'delegations_users'
  self.inheritance_column = :some_expletive_how_rails_makes_you_feel_or_whatever

  belongs_to :delegation, class_name: 'User'
  belongs_to :user
end
