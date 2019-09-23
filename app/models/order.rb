class Order < ApplicationRecord
  include Concerns::ScopeIfPresence
  include DefaultPagination
  include LogSendMailFailure

  belongs_to :inventory_pool
  belongs_to :user
  belongs_to :customer_order
  has_many :reservations
  has_many :item_lines
  has_many :option_lines
  has_many :models, -> { reorder(nil).distinct }, through: :item_lines
  has_many :items, -> { reorder(nil).distinct }, through: :item_lines
  has_many :options, -> { reorder(nil).distinct }, through: :option_lines

  class << self
    def submitted
      where(state: :submitted)
    end

    def rejected
      where(state: :rejected)
    end

    def approved
      where(state: :approved)
    end

    # NOTE: assumes `joins(:reservations)`
    def with_some_line_not_in_any_contract
      where(reservations: { contract: nil })
        .distinct
    end
  end

  validate do
    unless user.access_right_for(inventory_pool)
      errors.add \
        :base,
        _('User does not have access to inventory pool: %s') \
          % inventory_pool.name
    end

    if user.access_right_for(inventory_pool).try(&:suspended?) \
        and state != 'rejected'
      errors.add \
        :base,
        _('User is suspended for inventory pool: %s') \
          % inventory_pool.name
    end

    if reservations.map(&:delegated_user).uniq.count > 1
      errors.add \
        :base,
        _('An order can not have multiple delegated users.')
    end
  end

  #################################################################################

  scope :with_verifiable_user, (lambda do
    where <<-SQL
      EXISTS (
        SELECT 1
        FROM entitlement_groups_users
        INNER JOIN entitlement_groups
          ON entitlement_groups.id = entitlement_groups_users.entitlement_group_id
        WHERE entitlement_groups_users.user_id = orders.user_id
          AND entitlement_groups.is_verification_required = TRUE
          AND entitlement_groups.inventory_pool_id = orders.inventory_pool_id
      )
    SQL
  end)

  # NOTE: assumes `joins(:reservations)`
  scope :with_verifiable_user_and_model, (lambda do
    joins(<<-SQL)
      INNER JOIN entitlements
        ON entitlements.model_id = reservations.model_id
      INNER JOIN entitlement_groups
        ON entitlements.entitlement_group_id = entitlement_groups.id
      INNER JOIN entitlement_groups_users
        ON entitlement_groups.id = entitlement_groups_users.entitlement_group_id
    SQL
      .where(<<-SQL)
        entitlement_groups.is_verification_required IS TRUE
        AND entitlement_groups_users.user_id = reservations.user_id
        AND entitlement_groups.inventory_pool_id = reservations.inventory_pool_id
      SQL
      .distinct
  end)

  scope :no_verification_required, (lambda do
    where.not(
      id: \
        Order
        .unscoped # have to be used here, `Order` uses current scope (WTF) !!!
        .joins(:reservations)
        .with_verifiable_user_and_model
        .select(:id)
    )
  end)

  def to_be_verified?
    Order
      .joins(:reservations)
      .with_verifiable_user_and_model.where(id: id).exists?
  end

  #################################################################################

  scope :filter2, (lambda do |params, user = nil, inventory_pool = nil|
    orders = if user
               user.orders
             elsif inventory_pool
               inventory_pool.orders
             else
               all
             end

    orders = \
      orders
      .joins(:reservations)
      .with_some_line_not_in_any_contract
      .scope_if_presence(params[:status]) do |orders, states|
        orders.where(state: states)
      end
      .scope_if_presence(params[:search_term]) do |orders, search_term|
        orders.search(params[:search_term])
      end
      .scope_if_presence(params[:id]) do |orders, ids|
        orders.where(id: ids)
      end
      .scope_if_presence(params[:reservation_ids]) do |orders, reservation_ids|
        orders
          .where(reservations: { id: reservation_ids })
          .distinct
      end
      .scope_if_presence(params[:no_verification_required],
                         &:no_verification_required)
      .scope_if_presence(params[:to_be_verified],
                         &:with_verifiable_user_and_model)
      .scope_if_presence(params[:from_verifiable_users],
                         &:with_verifiable_user)
      .scope_if_presence(params[:range].try(:[], :start_date)) \
        do |orders, start_date|
        orders.where('orders.created_at >= ?', start_date)
      end
      .scope_if_presence(params[:range].try(:[], :end_date)) \
        do |orders, end_date|
        orders.where('orders.created_at <= ?', end_date)
      end
      .order('orders.created_at DESC')
      .distinct

    orders.default_paginate(params)
  end)

  # NOTE: assumes `joins(:reservations)`
  def self.search(query)
    return all if query.blank?

    sql = distinct
      .joins('INNER JOIN users ON users.id = reservations.user_id')
      .joins(<<-SQL)
        LEFT JOIN users delegated_users
        ON delegated_users.id = reservations.delegated_user_id
      SQL
      .joins('LEFT JOIN options ON options.id = reservations.option_id')
      .joins('LEFT JOIN models ON models.id = reservations.model_id')
      .joins('LEFT JOIN items ON items.id = reservations.item_id')

    query.split.map(&:strip).each do |q|
      qq = "%#{q}%"
      sql = sql.where(
        User.arel_table[:login].matches(qq)
          .or(User.arel_table[:firstname].matches(qq))
          .or(User.arel_table[:lastname].matches(qq))
          .or(User.arel_table[:badge_id].matches(qq))
          .or(Arel::Table.new('delegated_users')[:login].matches(qq))
          .or(Arel::Table.new('delegated_users')[:firstname].matches(qq))
          .or(Arel::Table.new('delegated_users')[:lastname].matches(qq))
          .or(Arel::Table.new('delegated_users')[:badge_id].matches(qq))
          .or(Model.arel_table[:manufacturer].matches(qq))
          .or(Model.arel_table[:product].matches(qq))
          .or(Model.arel_table[:version].matches(qq))
          .or(Option.arel_table[:product].matches(qq))
          .or(Option.arel_table[:version].matches(qq))
          .or(Item.arel_table[:inventory_code].matches(qq))
          .or(Order.arel_table[:purpose].matches(qq))
      )
    end
    sql
  end

  #################################################################################

  def reject(comment, current_user)
    update_attributes(state: :rejected, reject_reason: comment) and
      reservations.all? { |line| line.update_attributes(status: :rejected) } and
      Notification.order_rejected(self, comment, true, current_user)
  end

  #################################################################################

  def send_approved_notification(comment, send_mail, current_user)
    with_logging_send_mail_failure do
      Notification.order_approved(self, comment, send_mail, current_user)
    end
  end

  def send_submitted_notification
    with_logging_send_mail_failure do
      Notification.order_submitted(self, true)
    end
  end

  def send_received_notification
    with_logging_send_mail_failure do
      Notification.order_received(self, true)
    end
  end

  def approve(comment, send_mail = true, current_user = nil, force = false)
    if approvable? \
        or (force and current_user.has_role?(:lending_manager, inventory_pool))
      update_attributes(state: :approved)
      reservations.each { |cl| cl.update_attributes(status: :approved) }
      send_approved_notification(comment, send_mail, current_user)
      true
    else
      false
    end
  end

  def approvable?
    self_approvable? and \
      begin
        if reservations.all?(&:approvable?)
          true
        else
          uniq_reservations_error_messages.each { |m| errors.add(:base, m) }
          false
        end
      end
  end

  def self_approvable?
    if state == :approved
      errors.add(:base, _('This order has already been approved.'))
    end
    if user.suspended?(inventory_pool)
      errors.add(:base, _('This user is suspended.'))
    end
    if purpose.blank?
      errors.add(:base, _('Please provide a purpose...'))
    end
    errors.empty?
  end

  def uniq_reservations_error_messages
    reservations.flat_map { |r| r.errors.full_messages }.uniq
  end

  def target_user
    if user.delegation? and delegated_user
      delegated_user
    else
      user
    end
  end

  ############################################

  def min_date
    unless reservations.blank?
      # min(&:start_date) does not work here
      # rubocop:disable Style/SymbolProc
      reservations.min { |x| x.start_date }[:start_date]
      # rubocop:enable Style/SymbolProc
    end
  end

  def max_date
    unless reservations.blank?
      # min(&:end_date) does not work here
      # rubocop:disable Style/SymbolProc
      reservations.max { |x| x.end_date }[:end_date]
      # rubocop:enable Style/SymbolProc
    end
  end

  def max_range
    return nil if reservations.blank?
    line = reservations.max_by { |x| Integer(x.end_date - x.start_date) }
    Integer(line.end_date - line.start_date) + 1
  end

  ############################################

  def delegated_user
    reservations.map(&:delegated_user).uniq.first
  end
end
