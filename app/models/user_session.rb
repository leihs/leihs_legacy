class UserSession < ApplicationRecord
  belongs_to :user
  belongs_to :delegation, foreign_key: :delegation_id, class_name: 'User'
end
