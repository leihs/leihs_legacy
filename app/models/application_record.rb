class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def label_for_audits
    inspect
  end
end
