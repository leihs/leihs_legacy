# frozen_string_literal: true

# A Visit is an event on a particular date, on which a specific
# customer should come to pick up or return items - or from the other perspective:
# when an inventory pool manager should hand over some items to
# or get them back from the customer.
#
# No MySQL table, reading a query result
class Visit < ApplicationRecord
  include LineModules::GroupedAndMergedLines
  include DefaultPagination

  #######################################################
  def readonly?
    true
  end

  self.table_name = 'reservations'
  self.primary_key = 'visit_id'

  def id
    visit_id
  end

  VISIT_ID_SQL_EXPR = <<-SQL
    ENCODE(
      DIGEST(
        CONCAT_WS('_',
                  date,
                  reservations.inventory_pool_id,
                  reservations.user_id,
                  status),
        'sha1'),
      'hex')
  SQL

  default_scope do
    select(<<-SQL)
      date, reservations.inventory_pool_id, reservations.user_id, status,
      SUM(quantity) AS quantity,
      #{VISIT_ID_SQL_EXPR} AS visit_id
    SQL
    .from(<<-SQL)
      (SELECT
        CASE WHEN status = 'signed' THEN end_date ELSE start_date END AS date,
        inventory_pool_id,
        inventory_pools.name AS inventory_pool_name,
        user_id,
        status,
        quantity
       FROM reservations
       JOIN inventory_pools ON inventory_pools.id = inventory_pool_id
       WHERE status IN ('submitted', 'approved','signed')) AS reservations
    SQL
    .group('user_id, status, date, inventory_pool_id, inventory_pool_name')
    .order('date')
  end

  #######################################################

  belongs_to :user
  belongs_to :inventory_pool

  has_many :reservations, (lambda do |r|
    if r.status == :approved
      where(start_date: r.date)
    else
      where(end_date: r.date)
    end.where(inventory_pool_id: r.inventory_pool_id, user_id: r.user_id)
  end), foreign_key: :status, primary_key: :status

  def reservation_ids
    reservations.pluck(:id)
  end

  #######################################################

  scope :potential_hand_over, -> { where(status: :submitted) }
  scope :hand_over, -> { where(status: :approved) }
  scope :take_back, -> { where(status: :signed) }
  scope :take_back_overdue, -> { take_back.where('date < ?', Time.zone.today) }

  #######################################################

  scope :search, lambda { |query|
    sql = where.not(status: :submitted)
    return sql if query.blank?

    # TODO: search on reservations' models and items
    query.split.each do|q|
      q = "%#{q}%"
      sql = sql.where(User.arel_table[:login].matches(q)
                      .or(User.arel_table[:firstname].matches(q))
                      .or(User.arel_table[:lastname].matches(q))
                      .or(User.arel_table[:badge_id].matches(q)))
    end
    sql.joins(:user)
  }

  def self.filter(params, inventory_pool = nil)
    visits = if inventory_pool.nil?
               all
             else
               inventory_pool.visits
             end.where.not(status: :submitted)
    visits = visits.where(status: params[:status]) if params[:status]
    visits = visits.search(params[:search_term]) unless params[:search_term].blank?
    if params[:date] and params[:date_comparison] == 'lteq'
      visits = visits.where arel_table[:date].lteq(params[:date])
    end
    if params[:date] and params[:date_comparison] == 'eq'
      visits = visits.where arel_table[:date].eq(params[:date])
    end

    if r = params[:range]
      if r[:start_date]
        visits = visits.where(arel_table[:date].gteq(r[:start_date]))
      end
      visits = visits.where(arel_table[:date].lteq(r[:end_date])) if r[:end_date]
    end

    visits
  end

  def action
    case status
    when :submitted
        :potential_hand_over
    when :approved
        :hand_over
    when :signed
        :take_back
    end
  end

  def status
    read_attribute(:status).to_sym
  end

  def self.total_count_for_paginate
    scope_sql = Visit.all.reorder(nil).to_sql
    ApplicationRecord.connection.execute(scope_sql).count
  end

  def visit_as_json
    as_json(methods: [:reservation_ids, :action]).merge('id' => visit_id)
  end

end
