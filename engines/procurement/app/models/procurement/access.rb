module Procurement
  class Access < ApplicationRecord

    belongs_to :user
    belongs_to :organization

    has_many :requests, foreign_key: :user_id, primary_key: :user_id

    validates_presence_of :user
    validates_presence_of :organization, unless: proc { |r| r.is_admin }
    validates_uniqueness_of :user, scope: :is_admin

    validate do
      if user.delegation?
        errors.add(:base,
                   'Procurement access is not granted to delegations.')
      end
    end

    scope :requesters, -> { where(is_admin: [nil, false]) }
    scope :admins, -> { where(is_admin: true) }

    class << self
      def admin?(user)
        admins.where(user_id: user).exists?
      end

      def some_access?(user)
        where(user_id: user).exists? \
          or Procurement::Category.inspector_of_any_category?(user) \
          or Procurement::Access.admin?(user) \
          or (admins.empty? and user.is_admin)
      end

    end

  end
end
