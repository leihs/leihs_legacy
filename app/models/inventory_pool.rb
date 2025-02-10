# frozen_string_literal: true

class InventoryPool < ApplicationRecord
  include Availability::InventoryPool

  #################################################################################
  default_scope do
    where(is_active: true)
  end
  #################################################################################

  after_save do
    unless is_active?
      reservations.unsubmitted.destroy_all
    end
  end

  has_one :workday, dependent: :delete
  accepts_nested_attributes_for :workday, update_only: true

  has_many :holidays, dependent: :delete_all do
    def render_for_email_template
      future.inject([]) do |res, h|
        span = if h.start_date == h.end_date
                 I18n.l(h.start_date)
               else
                 "#{I18n.l(h.start_date, format: :without_year)} - #{I18n.l(h.end_date)}"
               end
        res << "#{h.name}: #{span}"
      end.join("\n")
    end
  end

  accepts_nested_attributes_for(:holidays,
                                allow_destroy: true,
                                reject_if: proc { |holiday| holiday[:id] })

  has_many :access_rights, dependent: :delete_all

  has_many(:users, -> { distinct }, through: :access_rights)

  has_many :suspensions, dependent: :delete_all

  has_many(:suspended_users,
           (lambda do
            where.not(suspensions: { suspended_until: nil })
              .where('suspensions.suspended_until >= ?', Time.zone.today)
              .distinct
            end),
           through: :suspensions, source: :user)

  has_many :rooms, -> { distinct }, through: :items
  has_many :items, dependent: :restrict_with_exception
  has_many(:own_items,
           class_name: 'Item',
           foreign_key: 'owner_id',
           dependent: :restrict_with_exception)
  has_many :models, -> { distinct }, through: :items
  has_many :options

  has_and_belongs_to_many :model_groups
  has_and_belongs_to_many :templates, -> { where(type: 'Template') },
                          join_table: 'inventory_pools_model_groups',
                          association_foreign_key: 'model_group_id'

  has_and_belongs_to_many :accessories

  has_many :reservations, dependent: :restrict_with_exception
  has_many :item_lines, dependent: :restrict_with_exception
  has_many :visits
  has_many :orders
  has_many :contracts

  has_many :entitlement_groups do
    def with_general
      all + [EntitlementGroup::GENERAL_GROUP_ID]
    end
  end

  has_many :mail_templates, dependent: :delete_all

  def suppliers
    Supplier
      .joins(:items)
      .where(':id IN (items.owner_id, items.inventory_pool_id)', id: id)
      .distinct
  end

  def buildings
    Building
      .joins(:items)
      .where(':id IN (items.owner_id, items.inventory_pool_id)', id: id)
      .distinct
  end

  #######################################################################

  def owner_or_responsible_for?(item)
    self == item.owner or self == item.inventory_pool
  end

  #######################################################################

  # - we don't recalculate the past
  # - if an item is already assigned, we block the availability
  #   even if the start_date is in the future (NOTE: really ???)
  # - if an item is already assigned but not handed over,
  #   it's never considered as late even if end_date is in the past
  # - we ignore the option_lines
  # - we get all reservations which are not rejected or closed
  # - we ignore reservations that are not handed over which the end_date is
  #   already in the past
  # - we consider even unsubmitted reservations, but not the already timed out ones
  has_many :running_reservations, (lambda do
   select(<<-SQL)
     reservations.id,
     reservations.inventory_pool_id,
     reservations.model_id,
     reservations.item_id,
     reservations.quantity,
     reservations.start_date,
     reservations.end_date,
     reservations.returned_date,
     reservations.status,
     ARRAY(
       SELECT egu.entitlement_group_id
       FROM entitlement_groups_users egu
       INNER JOIN entitlement_groups eg
       ON eg.id = egu.entitlement_group_id
       WHERE egu.user_id = reservations.user_id
       ORDER BY eg.name ASC
     ) AS user_group_ids
    SQL
     .joins('LEFT JOIN items ON reservations.item_id = items.id')
     .where(<<-SQL)
       reservations.item_id IS NULL OR items.is_borrowable = TRUE
     SQL
     .where(<<-SQL)
       reservations.status NOT IN ('draft', 'rejected', 'canceled', 'closed')
       AND NOT (
         reservations.status = 'unsubmitted' AND
         reservations.updated_at < '#{Time.now.utc - Setting.first.timeout_minutes.minutes}'
       )
       AND NOT (
         reservations.end_date < '#{Time.zone.today}' AND
         reservations.item_id IS NULL
       )
     SQL
  end), class_name: 'ItemLine'

  #######################################################################

  validates_presence_of :name, :shortname, :email
  validates_presence_of :automatic_suspension_reason, if: :automatic_suspension?

  validates_uniqueness_of :name

  validates :email, format: /@/, allow_blank: true

  validate :validate_inactive_conditions

  #######################################################################

  scope :search, lambda { |query|
    sql = all
    return sql if query.blank?

    query.split.each do|q|
      q = "%#{q}%"
      sql = sql.where(arel_table[:name].matches(q)
                      .or(arel_table[:shortname].matches(q))
                      .or(arel_table[:description].matches(q)))
    end
    sql
  }

  #######################################################################

  def to_s
    "#{name}"
  end

  # compares two objects in order to sort them
  def <=>(other)
    self.name.casecmp other.name
  end

  #######################################################################

  def next_open_date(x = Time.zone.today)
    if workday.closed_days.size < 7
      until open_on?(x)
        holiday = running_holiday_on(x)
        if holiday
          x = holiday.end_date.tomorrow
        else
          x += 1.day
        end
      end
    end
    x
  end

  def last_open_date(x = Time.zone.today)
    if workday.closed_days.size < 7
      until open_on?(x)
        holiday = running_holiday_on(x)
        if holiday
          x = holiday.start_date.yesterday
        else
          x -= 1.day
        end
      end
    end
    x
  end

  def open_on?(date)
    workday.open_on?(date) and running_holiday_on(date).nil?
  end

  def running_holiday_on(date)
    holidays.find_by(['start_date <= :d AND end_date >= :d', { d: date }])
  end

  ################################################################################

  def borrowable_items?
    items
      .where(items: { retired: nil,
                      is_borrowable: true,
                      parent_id: nil })
      .exists?
  end

  ################################################################################

  def inventory(params)
    model_type = case params[:type]
                 when 'item' then 'model'
                 when 'license' then 'software'
                 when 'option' then 'option'
                 end

    model_filter_params = \
      params.clone.merge(paginate: 'false',
                         search_targets: [:manufacturer,
                                          :product,
                                          :version,
                                          :items],
                         type: model_type)

    # if there are NOT any params related to items
    if [:is_borrowable,
        :retired,
        :category_id,
        :in_stock,
        :incomplete,
        :broken,
        :owned,
        :responsible_inventory_pool_id].all? { |param| params[param].blank? }
      # and one does not explicitly ask for software, models or used/unused models
      unless ['model', 'software'].include?(model_type) or params[:used]
        # then include options
        options = Option.filter(params.clone.merge(paginate: 'false',
                                                   sort: 'product',
                                                   order: 'ASC'),
                                self)
      end
    end

    # exlude models if asked only for options
    unless model_type == 'option'
      items = Item.filter(params.clone.merge(paginate: 'false', search_term: nil),
                          self)
      models = Model.filter model_filter_params.merge(items: items), self
    else
      models = []
    end

    inventory = \
      (models + (options || []))
        .sort { |a, b| a.name.strip <=> b.name.strip }

    unless params[:paginate] == 'false'
      inventory = inventory.default_paginate params
    end
    inventory
  end

  ITEM_PARAMS_FOR_CSV_EXPORT = \
    [:unborrowable,
     :retired,
     :category_id,
     :in_stock,
     :incomplete,
     :broken,
     :owned,
     :responsible_inventory_pool_id,
     :unused_models]

  def self.objects_for_export(inventory_pool, params)
    items = if params[:type] != 'option'
              if inventory_pool
                Item.filter(params.clone.merge(paginate: 'false', all: 'true'),
                            inventory_pool)
              else
                Item.unscoped
              end.includes(:current_reservation)
            else
              []
            end

    options = if inventory_pool
                if params[:type] != 'license' \
                    and ITEM_PARAMS_FOR_CSV_EXPORT.all? { |p| params[p].blank? }
                  Option.filter \
                    params.clone.merge(paginate: 'false',
                                       sort: 'product',
                                       order: 'ASC'),
                    inventory_pool
                else
                  []
                end
              else
                Option.unscoped
              end

    global = if inventory_pool
               false
             else
               true
             end

    include_params = [:room, :inventory_pool, :owner, :supplier]
    include_params += \
      (global ? [:model] : [:item_lines, model: [:model_links, :model_groups]])

    objects = []
    unless items.blank?
      items.includes(include_params).find_each do |i, index|
        # How could an item ever be nil?
        objects << i.to_csv_array(global: global) unless i.nil?
      end
    end
    unless options.blank?
      options.includes(:inventory_pool).find_each do |o|
        objects << o.to_csv_array unless o.nil? # How could an item ever be nil?
      end
    end
    objects
  end

  def self.header_for_export(objects_for_export)
    objects_for_export.flat_map(&:keys).uniq
  end

  def self.csv_export(inventory_pool, params)
    objects = objects_for_export(inventory_pool, params)
    header = header_for_export(objects)

    Export.csv_string header, objects
  end

  def self.excel_export(inventory_pool, params)
    objects = objects_for_export(inventory_pool, params)
    header = header_for_export(objects)

    Export.excel_string header, objects,
                        worksheet_name: _('Inventory')
  end

  def csv_import(inventory_pool, csv_file)
    require 'csv'

    items = []

    transaction(requires_new: true) do
      CSV.foreach(csv_file,
                  col_sep: ',',
                  quote_char: "\"",
                  headers: :first_row) do |row|
        unless row['inventory_code'].blank?
          item = \
            inventory_pool
              .items
              .create(inventory_code: row['inventory_code'].strip,
                      model: Model.find(row['model_id']),
                      is_borrowable: (row['is_borrowable'] == '1' ? 1 : 0),
                      is_inventory_relevant: \
                        (row['is_inventory_relevant'] == '0' ? 0 : 1)) do |i|
                          csv_import_helper(row, i)
                        end

          item.valid?
          items << item
        end
      end

      raise ActiveRecord::Rollback unless items.all?(&:valid?)
    end

    items
  end

  private

  def validate_inactive_conditions
    unless is_active?
      if orders_or_signed_contracts?
        errors.add \
          :base,
          _("Inventory pool can't be deactivated " \
            'due to existing orders or signed contracts.')
      end

      if owns_or_has_not_retired_items?
        errors.add \
          :base,
          _("Inventory pool can't be deactivated " \
            'due to existing items which are not yet retired.')
      end
    end
  end

  def orders_or_signed_contracts?
    reservations.submitted.exists? or
      reservations.approved.exists? or
      reservations.signed.exists?
  end

  def owns_or_has_not_retired_items?
    Item
      .where('inventory_pool_id = ? OR owner_id = ?', id, id)
      .where(retired: nil)
      .exists?
  end

  def csv_import_helper(row, i)
    unless row['serial_number'].blank?
      i.serial_number = row['serial_number']
    end
    unless row['note'].blank?
      i.note = row['note']
    end
    unless row['invoice_number'].blank?
      i.invoice_number = row['invoice_number']
    end
    unless row['invoice_date'].blank?
      i.invoice_date = row['invoice_date']
    end
    unless row['price'].blank?
      i.price = row['price']
    end
    unless row['supplier_name'].blank?
      i.supplier = \
        Supplier.find_or_create_by(name: row['supplier_name'])
    end
    unless row['building_id'].blank? and row['room_id'].blank?
      building = Building.find_by_id(name: row['building_id'])
      i.room = Room.find_by(id: row['room_id'], building_id: building.id)
    end
    unless row['properties_anschaffungskategorie'].blank?
      i.properties[:anschaffungskategorie] = \
        row['properties_anschaffungskategorie']
    end
    unless row['properties_project_number'].blank?
      i.properties[:reference] = 'investment'
      i.properties[:project_number] = row['properties_project_number']
    end
  end

end
