class EmailVisit < ApplicationRecord
  self.table_name = 'emails_visits'
  self.primary_key = [:email_id, :visit_id]

  belongs_to :email
end
