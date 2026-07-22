class Email < ApplicationRecord
  has_many :email_visits
  has_many :visits, through: :email_visits
end
