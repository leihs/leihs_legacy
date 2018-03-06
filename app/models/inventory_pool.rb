# frozen_string_literal: true

require_dependency 'model' # in tests Model constant seems not to autoload properly

class InventoryPool < ApplicationRecord
  include Availability::InventoryPool
  audited

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

  belongs_to :address

  has_one :workday, dependent: :delete
  accepts_nested_attributes_for :workday

  has_many :holidays, dependent: :delete_all
  accepts_nested_attributes_for(:holidays,
                                allow_destroy: true,
                                reject_if: proc { |holiday| holiday[:id] })

  has_many :access_rights, dependent: :delete_all
  has_many(:users,
           -> { where(access_rights: { deleted_at: nil }).distinct },
           through: :access_rights)
  has_many(:suspended_users,
           (lambda do
             where(access_rights: { deleted_at: nil })
               .where
               .not(access_rights: { suspended_until: nil })
               .where('access_rights.suspended_until >= ?', Time.zone.today)
               .distinct
           end),
           through: :access_rights, source: :user)

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
     id,
     inventory_pool_id,
     model_id,
     item_id,
     quantity,
     start_date,
     end_date,
     returned_date,
     status,
     string_agg(entitlement_groups_users.entitlement_group_id::text,
                ',') AS concat_group_ids
    SQL
     .joins(<<-SQL)
       LEFT JOIN entitlement_groups_users
       ON entitlement_groups_users.user_id = reservations.user_id
     SQL
     .where(<<-SQL)
       status NOT IN ('rejected', 'closed')
       AND NOT (
         status = 'unsubmitted' AND
         updated_at < '#{Time.now.utc - Setting.first.timeout_minutes.minutes}'
       )
       AND NOT (
         end_date < '#{Time.zone.today}' AND
         item_id IS NULL
       )
     SQL
     .group(:id)
  end), class_name: 'ItemLine'

  #######################################################################

  before_create :create_workday

  validates_presence_of :name, :shortname, :email
  validates_presence_of :automatic_suspension_reason, if: :automatic_suspension?

  validates_uniqueness_of :name

  validates :email, format: /@/, allow_blank: true

  validate :validate_inactive_conditions

  after_save do
    if automatic_access and automatic_access_changed?
      AccessRight
        .connection
        .execute('INSERT INTO access_rights ' \
                   '(role, inventory_pool_id, user_id, created_at, updated_at) ' \
                 "SELECT 'customer', '#{id}', users.id, NOW(), NOW() " \
                 'FROM users ' \
                 'LEFT JOIN access_rights ' \
                 'ON access_rights.user_id = users.id ' \
                 "AND access_rights.inventory_pool_id = '#{id}' " \
                 'WHERE access_rights.user_id IS NULL;')
    end
  end

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

  def label_for_audits
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

  def update_address(attr)
    if (a = Address.find_by(attr))
      update_attributes(address_id: a.id)
    else
      create_address(attr)
    end
  end

  def create_workday
    self.workday ||= Workday.new
  end

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

    transaction do
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
