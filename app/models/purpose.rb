class Purpose < ActiveRecord::Base
  audited
  has_many :reservations

  # TODO: delete not associated purposes
  # validates has at least one reservation

  def to_s
    "#{description}"
  end

  def label_for_audits
    to_s
  end

end
