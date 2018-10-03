class AuthenticationSystemUser < ApplicationRecord
  self.table_name = 'authentication_systems_users'

  belongs_to :user
  belongs_to :authentication_system
end
