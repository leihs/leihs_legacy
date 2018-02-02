# frozen_string_literal: true

# A Visit is an event on a particular date, on which a specific
# customer should come to pick up or return items - or from the other perspective:
# when an inventory pool manager should hand over some items to
# or get them back from the customer.

class Visit < ApplicationRecord
  include LineModules::GroupedAndMergedLines
  include DefaultPagination

  def readonly?
    true
  end

  self.table_name = 'visits'
  self.primary_key = 'id'
  self.inheritance_column = nil

  default_scope do
    order(:date, :id)
  end

  belongs_to :user
  belongs_to :inventory_pool

  #################################################################################
  def reservations
    Reservation.where(id: reservation_ids)
  end
  #################################################################################

  scope :potential_hand_over, (lambda do
    where(type: :hand_over).where(is_approved: false)
  end)
  scope :hand_over, -> { where(type: :hand_over).where(is_approved: true) }
  scope :take_back, -> { where(type: :take_back) }
  scope :take_back_overdue, -> { take_back.where('date < ?', Time.zone.today) }

  scope :search, lambda { |query|
    sql = where(is_approved: true)
    return sql if query.blank?

    # TODO: search on reservations' models and items
    query.split.each do |q|
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
             end.where(is_approved: true)

    if params[:status]
      visits = visits.where(
        type: case params[:status]
              when ['approved', 'signed'] then ['hand_over', 'take_back']
              when 'approved' then 'hand_over'
              when 'signed' then 'take_back'
              end
      )
    end

    if params[:verification].presence
      visits = case params[:verification]
               when 'with_user_to_verify'
                 visits.where(with_user_to_verify: true)
               when 'with_user_and_model_to_verify'
                 visits.where(with_user_and_model_to_verify: true)
               when 'no_verification'
                 visits.where(with_user_to_verify: false,
                              with_user_and_model_to_verify: false)
               else
                 visits
               end
    end

    unless params[:search_term].blank?
      visits = visits.search(params[:search_term])
    end

    if params[:date] and params[:date_comparison] == 'lteq'
      visits = visits.where arel_table[:date].lteq(params[:date])
    end

    if params[:date] and params[:date_comparison] == 'eq'
      visits = visits.where arel_table[:date].eq(params[:date])
    end

    if r = params[:range]
      if r[:start_date].presence
        visits = visits.where(arel_table[:date].gteq(r[:start_date]))
      end
      if r[:end_date].presence
        visits = visits.where(arel_table[:date].lteq(r[:end_date]))
      end
    end

    visits
  end

  def self.total_count_for_paginate
    scope_sql = Visit.all.reorder(nil).to_sql
    ApplicationRecord.connection.execute(scope_sql).count
  end

  #################################################################################
  ################## TO MAINTAIN COMPATIBILITY WITH OLD SCHISL ####################
  #################################################################################

  def action
    type
  end

  def status
    case [self.type.to_sym, self.is_approved?]
    when [:hand_over, false] then :submitted
    when [:hand_over, true] then :approved
    when [:take_back, true] then :signed
    end
  end

  def visit_as_json
    as_json(methods: [:reservation_ids, :action, :status]).merge('visit_id' => id)
  end

  #################################################################################
  #################################################################################
  #################################################################################

end
