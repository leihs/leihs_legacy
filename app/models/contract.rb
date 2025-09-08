class Contract < ApplicationRecord
  include ScopeIfPresence
  include TimeWindows
  include DefaultPagination
  include LineModules::GroupedAndMergedLines

  before_create do
    id = UUIDTools::UUID.random_create
    self.id = id
    b32 = Base32::Crockford.encode(id.to_i)
    self.compact_id ||= (3..26).lazy.map { |i| b32[0..i] } \
      .map { |c_id| !Contract.find_by(compact_id: c_id) && c_id } \
      .find(&:itself)
  end

  ORDER_BY = lambda do
    order('reservations.start_date ASC, ' \
          'reservations.end_date ASC, ' \
          'reservations.created_at ASC')
  end

  has_many :reservations,
           ORDER_BY,
           dependent: :destroy
  has_many :item_lines,
           ORDER_BY,
           dependent: :destroy
  has_many :option_lines,
           ORDER_BY,
           dependent: :destroy
  has_many :items, through: :item_lines
  has_many :options, -> { distinct }, through: :option_lines

  belongs_to :user
  belongs_to :inventory_pool, -> { unscope(where: :is_active) }

  #########################################################################

  scope :open, -> { where(state: :open) }
  scope :closed, -> { where(state: :closed) }

  #########################################################################

  def orders
    reservations.map(&:order).uniq
  end

  def delegated_user
    reservations.map(&:delegated_user).uniq.first
  end

  def handed_over_by_user
    reservations.map(&:handed_over_by_user).uniq.first
  end

  def total_quantity
    reservations.sum(:quantity)
  end

  def total_price
    reservations.to_a.sum(&:price)
  end

  #########################################################################

  def models
    Model.where(id: item_lines.map(&:model_id)).distinct
  end

  #########################################################################

  validate do
    if reservations.empty?
      errors.add(:base,
                 _('This contract is not signable because ' \
                   "it doesn't have any contract reservations."))
    else
      if reservations.any? { |line| not [:signed, :closed].include?(line.status) }
        errors.add(:base, _('The assigned contract reservations have to be ' \
                            'marked either as signed or as closed'))
      end
      if reservations.map(&:start_date).uniq.size != 1
        errors.add(:base, _('The start_date is not unique'))
      end
      unless reservations.all? &:item
        errors.add(:base, _('This contract is not signable because ' \
                            'some reservations are not assigned.'))
      end
      if reservations
        .where(status: :signed)
        .any? { |l| l.end_date < Time.zone.today }
        errors.add(
          :base,
          _('End date of a take back line can not be in the past.')
        )
      end
      if reservations.map(&:delegated_user).uniq.count > 1
        errors.add(:base, _("Contract can't have multiple delegated users."))
      end
      if reservations.map(&:handed_over_by_user).uniq.count > 1
        errors.add(:base, _("Contract can't have multiple handed over by users."))
      end
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
        WHERE entitlement_groups_users.user_id = contracts.user_id
          AND entitlement_groups.is_verification_required = TRUE
          AND entitlement_groups.inventory_pool_id = contracts.inventory_pool_id
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
        Contract
        .unscoped # have to be used here, `Contract` uses current scope (WTF) !!!
        .joins(:reservations)
        .with_verifiable_user_and_model
        .reselect(:id)
    )
  end)

  def to_be_verified?
    Contract
      .joins(:reservations)
      .with_verifiable_user_and_model
      .where(id: id)
      .exists?
  end

  #########################################################################

  def self.filter2(params, user = nil, inventory_pool = nil, paginate: true)
    contracts = if user
                  user.contracts
                elsif inventory_pool
                  inventory_pool.contracts
                else
                  all
                end

    contracts = \
      contracts
      .joins(:reservations)
      .scope_if_presence(params[:status]) do |contracts, states|
        contracts.where(state: states)
      end
      .scope_if_presence(params[:search_term]) do |contracts, search_term|
        contracts.search(params[:search_term])
      end
      .scope_if_presence(params[:id]) do |contracts, ids|
        contracts.where(id: ids)
      end
      .scope_if_presence(params[:no_verification_required],
                         &:no_verification_required)
      .scope_if_presence(params[:to_be_verified],
                         &:with_verifiable_user_and_model)
      .scope_if_presence(params[:from_verifiable_users],
                         &:with_verifiable_user)
      .scope_if_presence(params[:range].try(:[], :start_date)) do |contracts, start_date|
        contracts.where('contracts.created_at >= ?', start_date)
      end
      .scope_if_presence(params[:range].try(:[], :end_date)) do |contracts, end_date|
        contracts.where('contracts.created_at <= ?', end_date)
      end
      .scope_if_presence(params[:global_contracts_search],
                         &:sort_for_global_search)
      .distinct

    if paginate
      contracts.default_paginate(params)
    else
      contracts
    end
  end

  #########################################################################

  # NOTE: assumes `joins(:reservations)`
  def self.search(query)
    return all if query.blank?

    sql = distinct \
      .joins('INNER JOIN users ON users.id = reservations.user_id')
      .joins(<<-SQL)
        LEFT JOIN users delegated_users
        ON delegated_users.id = reservations.delegated_user_id
      SQL
      .joins('LEFT JOIN orders ON reservations.order_id = orders.id')
      .joins('LEFT JOIN options ON options.id = reservations.option_id')
      .joins('LEFT JOIN models ON models.id = reservations.model_id')
      .joins('LEFT JOIN items ON items.id = reservations.item_id')

    query.split.map(&:strip).each do |q|
      qq = "%#{q}%"
      sql = sql.where(
        self.arel_table[:compact_id].matches(qq)
          .or(User.arel_table[:login].matches(qq))
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
          .or(Contract.arel_table[:purpose].matches(qq))
      )
    end
    sql
  end

  def self.sort_for_global_search
    select(<<-SQL)
      contracts.*,
      CASE
        WHEN contracts.state = 'closed' THEN contracts.created_at
        ELSE NULL
      END AS custom_created_at,
      users.firstname,
      bool_and(reservations.delegated_user_id IS NULL) AS not_for_delegation
    SQL
      .group(<<-SQL)
        contracts.id,
        reservations.contract_id,
        reservations.id,
        users.firstname
      SQL
      .order('contracts.state DESC')
      .order('custom_created_at DESC')
      .order('not_for_delegation DESC')
      .order('users.firstname ASC')
  end

  #########################################################################

  # compares two objects in order to sort them
  def <=>(other)
    self.created_at <=> other.created_at
  end

  def to_s
    "#{id}"
  end

  #########################################################################

  def self.sign!(current_user,
                 current_inventory_pool,
                 user,
                 selected_lines,
                 purpose,
                 note = nil,
                 delegated_user_id = nil)
    transaction(requires_new: true) do
      contract = Contract.new(state: :open,
                              purpose: purpose,
                              user: user,
                              inventory_pool: current_inventory_pool)
      contract.note = note

      selected_lines.each do |cl|
        attrs = {
          contract: contract,
          status: :signed,
          user: user,
          handed_over_by_user_id: current_user.id
        }

        if delegated_user_id
          attrs[:delegated_user] = user.delegated_users.find(delegated_user_id)
        end

        # Forces handover date to be today.
        attrs[:start_date] = Time.zone.today if cl.start_date != Time.zone.today

        cl.attributes = attrs

        contract.reservations << cl
      end
      contract.save!
      contract
    end
  end

end
