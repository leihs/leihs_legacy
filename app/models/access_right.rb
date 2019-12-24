class AccessRight < ApplicationRecord
  audited

  ### suspension virtual attributes ##################################
  # the point of these is to avoid changing all the frontendcode
  # after moving the suspensions to their own table

  attribute :suspended_until, :date
  attribute :suspended_reason, :text

  after_save do |access_right|
    if access_right.suspended_until.present?
      Suspension.find_or_initialize_by(
        user_id: access_right.user_id,
        inventory_pool_id: access_right.inventory_pool_id) \
        .update_attributes(
          suspended_until: access_right.suspended_until,
          suspended_reason: access_right.suspended_reason)
    else
      Suspension.find_or_initialize_by(
        user_id: access_right.user_id,
        inventory_pool_id: access_right.inventory_pool_id).try(&:destroy)
    end
  end

  after_initialize do |access_right|
    access_right.set_suspension_attributes
  end

  after_find do |access_right|
    access_right.set_suspension_attributes
  end

  after_touch do |access_right|
    access_right.set_suspension_attributes
  end

  def set_suspension_attributes
    self.suspended_until= self.suspension.try(:suspended_until)
    self.suspended_reason= self.suspension.try(:suspended_reason)
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

  before_destroy do
    check_for_existing_reservations
    throw :abort unless errors.empty?
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

  def label_for_audits
    to_s
  end

  def suspended?
    suspension = Suspension.find_by(
      user_id: self.user_id,
      inventory_pool_id: self.inventory_pool_id)
    (suspension and suspension.suspended_until >= Time.zone.today) or false
  end

  ####################################################################

  private

  def check_for_existing_reservations
    if inventory_pool
      reservations = inventory_pool.reservations.where(user_id: user)
      if reservations.submitted.exists? or reservations.approved.exists?
        errors.add(:base, _('Currently has open orders'))
      end
      if reservations.signed.exists?
        errors.add(:base, _('Currently has items to return'))
      end
    end
  end

end
