class EntitlementGroup < ApplicationRecord
  include Availability::Group
  include Search::Name

  belongs_to :inventory_pool

  has_and_belongs_to_many :users

  has_many :entitlements, dependent: :restrict_with_exception
  accepts_nested_attributes_for :entitlements, allow_destroy: true
  has_many(:models,
           -> { distinct },
           through: :entitlements,
           dependent: :restrict_with_exception)

  validates_presence_of :inventory_pool_id # tmp#2
  validates_presence_of :name

  # tmp#2 scope :general, -> {where(:name => 'General', :inventory_pool_id => nil)}

  ##########################################

  def to_s
    name
  end
end
