# A Reservation is differentiated into its subclasses #ItemLine and #OptionLine.
#
# Each Reservation refers to some borrowable thing - which can either
# be an #Option or a #Model. In the case of a #Model, it does not
# have specific instances of that #Model in the begining and only gets
# them once the manager chooses a specific #Item of the #Model that the
# customer wants.
#
class Reservation < ApplicationRecord
  include Availability::Reservation
  include Concerns::ScopeIfPresence
  include Delegation::Reservation

  belongs_to :inventory_pool, inverse_of: :reservations
  belongs_to :user, inverse_of: :reservations
  belongs_to :contract, inverse_of: :reservations
  belongs_to :order
  belongs_to :model
  belongs_to :handed_over_by_user, class_name: 'User'
  belongs_to :returned_to_user, class_name: 'User'

  has_many :entitlement_groups, through: :user

  def created_at_date_if_submitted
    created_at.strftime('%Y-%m-%d') if status == :submitted
  end

  #########################################################################

  STATUSES = [:unsubmitted, :submitted, :rejected, :approved, :signed, :closed]

  def status
    read_attribute(:status).to_sym
  end

  STATUSES.each do |status|
    scope status, -> { where(status: status) }
  end

  #########################################################################

  default_scope { order(:start_date, :end_date, :created_at) }

  scope(:handed_over_or_assigned_but_not_returned,
        (lambda do
          where(returned_date: nil)
            .where('NOT (end_date < ? AND item_id IS NULL)',
                   Time.zone.today)
        end))

  def self.filter(params, inventory_pool)
    reservations = inventory_pool.reservations

    reservations
      .scope_if_presence(params[:contract_ids]) do |rs, ids|
        reservations.where(contract_id: ids)
      end
      .scope_if_presence(params[:order_ids]) do |rs, ids|
        reservations.where(order_id: ids)
      end
      .scope_if_presence(params[:ids]) do |rs, ids|
        reservations.where(id: ids)
      end
  end

  #####################################################

  before_validation on: :create do
    self.start_date ||= Time.zone.today
    self.end_date ||= Time.zone.today

    if user.delegation?
      if order
        self.delegated_user ||= order.reservations.first.delegated_user
      else
        self.delegated_user ||= user.delegator_user
      end
    end
  end

  validates_numericality_of :quantity, greater_than: 0, only_integer: true
  validates_presence_of :user, :inventory_pool, :status
  validates_presence_of(:contract,
                        if: proc { |r| [:signed, :closed].include?(r.status) })
  validate :date_sequence
  validate do
    errors.add(:base, _('No access')) unless user.access_right_for(inventory_pool)
    if changed_attributes.keys.count == 1 and end_date_changed?
      # we skip delegation validation on end_date extension
    elsif returned_date
      # we skip delegation validation on returning (or returned) reservations
    else
      if user.delegation?
        unless user.delegated_users.include?(delegated_user)
          errors.add(:base,
                     _("Delegated user is not member of the contract's " \
                       'delegation or is empty'))
        end
      else
        if delegated_user
          errors.add(:base,
                     _("Delegated user must be empty for contract's normal user"))
        end
      end
    end
  end

  # only apply if self.class == Reservation, as ItemLine (< Reservation) defines
  # own specific validations for uniqueness of item_id
  validates_uniqueness_of \
    :item_id,
    scope: :returned_date,
    if: proc { |r| r.class == Reservation and r.item_id and r.returned_date.nil? }

  before_save do
    if returned_date and returned_date_changed?
      self.status = :closed
    end
  end

  before_destroy do
    if [:rejected, :signed, :closed].include? status
      raise 'A rejected, signed or closed reservation line cannot be destroyed!'
    end
  end

  ###############################################

  # compares two objects in order to sort them
  def <=>(other)
    # TODO: prevent name with leading and trailing whitespaces
    # directly on model and option save
    [self.start_date, self.model.name.strip] \
      <=> [other.start_date, other.model.name.strip]
  end

  def late?(current_date = Time.zone.today)
    returned_date.nil? and end_date < current_date
  end

  def reserved?
    start_date > Time.zone.today and item
  end

  ###############################################

  def visits_on_open_date?
    inventory_pool.open_on?(start_date) and inventory_pool.open_on?(end_date)
  end

  def start_date_within_advance_days_period?
    start_date < (Date.today + inventory_pool.workday.reservation_advance_days.day)
  end

  # custom valid? method
  def complete?
    self.valid? and self.available?
  end

  ###############################################

  def price
    (item.price || 0) * quantity
  end

  def price_or_max_price
    if item
      (item.price || 0) * quantity
    else
      (model
        .borrowable_items
        .where(inventory_pool_id: inventory_pool)
        .map(&:price)
        .compact
        .max || 0) \
      * quantity
    end
  end

  def target_user
    if user.delegation? and delegated_user
      delegated_user
    else
      user
    end
  end

  ############################################

  def submittable?
    if start_date_within_advance_days_period?
      errors.add(:base,
                 _('This order is not approvable because some reservations ' \
                   'violate the minimal reservation advance period of the ' \
                   'inventory pool. Please adjust the start date accordingly.'))
    end
    errors.empty?
  end

  def approvable?
    if delegated_user.try :suspended?, inventory_pool
      errors.add(:base,
                 _('The delegated user %s is suspended.') % delegated_user)
    end
    unless visits_on_open_date?
      errors.add(:base,
                 _('This order is not approvable because the inventory pool ' \
                   'is closed on either the start or enddate.'))
    end
    unless available?
      errors.add(:base,
                 _('This order is not approvable because some reserved ' \
                   'models are not available.'))
    end
    errors.empty?
  end

  def update_time_line(start_date, end_date, user)
    Reservation.transaction do
      start_date ||= self.start_date
      end_date ||= self.end_date
      unless update_attributes(start_date: start_date,
                               end_date: [start_date, end_date].max)
        raise errors.full_messages.uniq.join(', ')
      end
      if user.access_right_for(inventory_pool).role == :group_manager \
        and not available?
        raise _('Not available')
      end
    end
  end

  def last_closed_reservation_of_contract?
    contract.reservations.all? { |r| r.status == :closed }
  end

  ############################################

  private

  def date_sequence
    # OPTIMIZE: strange behavior: in some cases, this error raises when shouldn't
    if end_date < start_date
      errors.add(:base, _('Start Date must be before End Date'))
    end
    # TODO: Think about this a little bit more....
    # errors.add(:base, _("Start Date cannot be a past date"))
    # if start_date < Date.today
  end
end
