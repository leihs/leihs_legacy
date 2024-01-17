class AccessRight < ApplicationRecord

  self.primary_key = 'id'

  ### suspension virtual attributes ##################################
  # the point of these is to avoid changing all the frontendcode
  # after moving the suspensions to their own table

  attribute :suspended_until, :date
  attribute :suspended_reason, :text

  after_save do |access_right|
    if access_right.suspended_until.present?
      Suspension.find_or_initialize_by(
        user_id: access_right.user_id,
        inventory_pool_id: access_right.inventory_pool_id
      ).update(
        suspended_until: access_right.suspended_until,
        suspended_reason: access_right.suspended_reason
      )
    else
      Suspension.find_or_initialize_by(
        user_id: access_right.user_id,
        inventory_pool_id: access_right.inventory_pool_id
      ).try(&:destroy)
    end
  end

  after_initialize :set_suspension_attributes
  after_find :set_suspension_attributes
  after_touch :set_suspension_attributes

  def set_suspension_attributes
    self.suspended_until = self.suspension.try(:suspended_until)
    self.suspended_reason = self.suspension.try(:suspended_reason)
  end

  ####################################################################

  belongs_to :user, inverse_of: :access_rights
  belongs_to :inventory_pool, inverse_of: :access_rights

  def suspension
    Suspension.find_by(user: user, inventory_pool: inventory_pool)
  end

  # NOTE the elements have to be sorted in ascending order
  ROLES_HIERARCHY = [:customer,
                     :group_manager,
                     :lending_manager,
                     :inventory_manager]
  AVAILABLE_ROLES = ROLES_HIERARCHY

  AUTOMATIC_SUSPENSION_DATE = Date.today + 1000.years

  def role
    read_attribute(:role).to_sym
  end

  def role=(v)
    v = v.to_sym
    case v
    when :customer, :group_manager, :lending_manager, :inventory_manager
      write_attribute(:role, v)
    when :no_access
      self.destroy
    end
  end

  ####################################################################

  before_validation(on: :create) do
    if user
      unless user.access_rights.active.empty?
        if inventory_pool
          old_ar = \
            user.access_rights.active.find_by(inventory_pool_id: inventory_pool.id)
        end
        user.access_rights.delete(old_ar) if old_ar
      end
    end
  end

  ####################################################################

  scope :active, (lambda do
    joins(<<-SQL)
      LEFT JOIN inventory_pools
      ON inventory_pools.id = access_rights.inventory_pool_id
    SQL
    .where(<<-SQL)
      inventory_pools.is_active = 't'
    SQL
  end)

  scope :suspended, (lambda do
    joins(<<-SQL)
      LEFT JOIN suspensions
      ON (suspensions.user_id = access_rights.user_id
        AND  suspensions.inventory_pool_id = access_rights.inventory_pool_id)
    SQL
    where
      .not(suspended_until: nil)
      .where('suspended_until >= ?', Time.zone.today)
  end)

  ####################################################################

  def to_s
    s = _("#{role}".humanize)
    s += " #{_('for')} #{inventory_pool.name}" if inventory_pool
    s
  end

  def suspended?
    suspension = Suspension.find_by(
      user_id: self.user_id,
      inventory_pool_id: self.inventory_pool_id
    )
    (suspension and suspension.suspended_until >= Time.zone.today) or false
  end
end
