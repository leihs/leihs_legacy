# encoding: utf-8
# An Item is a borrowable thing (unless being flagged as
# not being borrowable), is an instance of a #Model, has
# its own barcode and thus its own identity. This is in
# contrast to an #Option, which does not have its own
# barcode and identity.
#
# Example:
# We can have a #Model "Wild Duck Black Pather snowboard"
# and three #Items of that #Model, one which was borrowed
# and two which are still available to be taken out for
# riding pleasure.
#
class Item < ApplicationRecord
  include Concerns::InventoryCode
  include Concerns::ItemCsv
  include Concerns::SerialNumberValidation
  include DefaultPagination
  audited

  belongs_to(:parent,
             class_name: 'Item',
             foreign_key: 'parent_id',
             inverse_of: :children)
  has_many(:children,
           class_name: 'Item',
           foreign_key: 'parent_id',
           dependent: :nullify,
           before_add: :check_child,
           after_add: :update_child_attributes)

  belongs_to :model, inverse_of: :items
  belongs_to :room, inverse_of: :items
  belongs_to(:owner,
             -> { unscope(where: :is_active) },
             class_name: 'InventoryPool',
             foreign_key: 'owner_id',
             inverse_of: :own_items)
  belongs_to :supplier
  belongs_to :inventory_pool,
             -> { unscope(where: :is_active) },
             inverse_of: :items

  has_many :item_lines, dependent: :restrict_with_exception
  alias_method :reservations, :item_lines

  has_one(:current_reservation,
          -> { where(returned_date: nil) },
          class_name: 'Reservation')

  has_many :attachments, dependent: :destroy
  accepts_nested_attributes_for :attachments, allow_destroy: true

  # Note: Rails correctly serializes Jsonb on its own. However, the
  # resulting hashes when reading from the DB contain string keys,
  # but no symbol keys. Since we still use symbol keys everywhere
  # to access the properties, we need the following serializer:
  serialize :properties, Concerns::HashSerializer

  ####################################################################

  validates_uniqueness_of :inventory_code, case_sensitive: false
  validates_presence_of :inventory_code, :model, :owner, :inventory_pool

  validate :validates_package, :validates_changes
  validates :retired_reason, presence: true, if: :retired?

  ####################################################################

  before_validation do
    self.owner ||= inventory_pool
    self.inventory_pool ||= owner

    self.inventory_code ||= Item.proposed_inventory_code(owner)
    self.retired_reason = nil unless retired?

    # we want remove empty values (and we keep it as HashWithIndifferentAccess)
    self.properties = properties.delete_if { |k, v| v.blank? }

    fields = \
      Field.all.select do |field|
        [nil, type.downcase].include?(field.data['target_type']) \
          and field.data.key?('default')
      end
    fields.each do |field|
      field.set_default_value(self)
    end
  end

  after_save :update_children_attributes

  ####################################################################

  SEARCHABLE_FIELDS = %w(inventory_code
                         serial_number
                         invoice_number
                         note
                         name
                         user_name
                         properties)

  scope :search, lambda { |query|
    return all if query.blank?

    q = query.split.map { |s| "%#{s}%" }
    model_fields_1 = Model::SEARCHABLE_FIELDS.map { |f| "m1.#{f}" }.join(', ')
    model_fields_2 = Model::SEARCHABLE_FIELDS.map { |f| "m2.#{f}" }.join(', ')
    item_fields_1 = Item::SEARCHABLE_FIELDS.map { |f| "i1.#{f}" }.join(', ')
    item_fields_2 = Item::SEARCHABLE_FIELDS.map { |f| "i2.#{f}" }.join(', ')
    room_fields = \
      Room::SEARCHABLE_FIELDS.map { |f| "r.#{f}" }.join(', ')
    joins(<<-SQL)
      INNER JOIN (SELECT i1.id,
                         CONCAT_WS(' ',
                                   #{model_fields_1},
                                   #{model_fields_2},
                                   #{item_fields_1},
                                   #{item_fields_2},
                                   #{room_fields}) AS text
                  FROM items AS i1
                  INNER JOIN models AS m1 ON i1.model_id = m1.id
                  LEFT JOIN items AS i2 ON i2.parent_id = i1.id
                  LEFT JOIN models AS m2 ON m2.id = i2.model_id
                  LEFT JOIN rooms AS r ON r.id = i1.room_id) AS full_text
      ON items.id = full_text.id
    SQL
    .where(Arel::Table.new(:full_text)[:text].matches_all(q))
  }

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.filter(params, inventory_pool = nil)
    items = Item.distinct
    items = items.send(params[:type].pluralize) unless params[:type].blank?

    items = items.by_owner_or_responsible inventory_pool if inventory_pool
    items = items.where(owner_id: inventory_pool) if params[:owned]
    if params[:responsible_inventory_pool_id]
      items = \
        items.where(inventory_pool_id: params[:responsible_inventory_pool_id])
    end

    items = items.where(id: params[:ids]) if params[:ids]
    items = items.where(id: params[:id]) if params[:id]
    items = items.retired if params[:retired] == 'true'
    items = items.unretired if params[:retired] == 'false'

    # there are 2 kinds of borrowable:
    # the first is item attribute
    if params[:is_borrowable]
      items = items.where(is_borrowable: (params[:is_borrowable] == 'true'))
    end
    # the second is item scope
    items = items.borrowable if params[:borrowable]

    items = items.unborrowable if params[:unborrowable]
    if params[:category_id]
      model_ids = if params[:category_id] == '00000000-0000-0000-0000-000000000000'
                    Model.where.not(id: Model.joins(:categories))
                  else
                    Model
                      .joins(:categories)
                      .where("model_groups.id": \
                               [Category.find(params[:category_id])] \
                               + Category.find(params[:category_id]).descendants)
                  end
      items = items.where(model_id: model_ids)
    end
    items = items.where(parent_id: params[:package_ids]) if params[:package_ids]
    items = items.where(parent_id: nil) if params[:not_packaged]
    if params[:packages]
      items = \
        items
          .joins(:model)
          .where(models: { is_package: (params[:packages] == 'true') })
    end
    items = items.in_stock if params[:in_stock]
    items = items.incomplete if params[:incomplete]
    items = items.broken if params[:broken]
    if params[:inventory_code]
      items = items.where(inventory_code: params[:inventory_code])
    end
    items = items.where(model_id: params[:model_ids]) if params[:model_ids]
    unless params[:before_last_check].blank?
      items = \
        items
          .where(arel_table[:last_check]
          .lteq(Date.strptime(params[:before_last_check],
                              I18n.translate('date.formats.default'))))
    end
    items = items.search(params[:search_term]) unless params[:search_term].blank?
    if params[:sort_by_inventory_code] == 'true'
      items = items.order(:inventory_code)
    end
    items = items.default_paginate params unless params[:paginate] == 'false'
    items
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  ####################################################################
  # preventing delete

  def self.delete_all
    false
  end

  before_destroy do
    if model.is_package? and reservations.empty?
      # NOTE only never handed over packages can be deleted
    else
      errors.add(:base, 'Item cannot be deleted')
      throw :abort
    end
  end

  scope :borrowable, -> { where(is_borrowable: true, parent_id: nil) }
  scope :unborrowable, -> { where(is_borrowable: false) }

  scope :retired, -> { where.not(retired: nil) }
  scope :unretired, -> { where(retired: nil) }

  scope :broken, -> { where(is_broken: true) }
  scope :incomplete, -> { where(is_incomplete: true) }

  scope :unfinished, -> { where(['inventory_code IS NULL OR model_id IS NULL']) }

  scope :inventory_relevant, -> { where(is_inventory_relevant: true) }
  scope :not_inventory_relevant, -> { where(is_inventory_relevant: false) }

  scope :packages, -> { joins(:model).where(models: { is_package: true }) }
  # temp# scope :packaged, -> {where("parent_id IS NOT NULL")}

  # Added parent_id to "in_stock" so items that are
  # in packages are considered to not be available
  scope(:in_stock,
        (lambda do
          joins('LEFT JOIN reservations AS cl001 ' \
                'ON items.id=cl001.item_id AND cl001.returned_date IS NULL')
            .where('cl001.id IS NULL AND items.parent_id IS NULL')
        end))
  scope(:not_in_stock,
        (lambda do
          joins('INNER JOIN reservations AS cl001 ' \
                'ON items.id=cl001.item_id AND cl001.returned_date IS NULL')
        end))

  scope(:by_owner_or_responsible,
        (lambda do |ip|
          where(':id IN (items.owner_id, items.inventory_pool_id)', id: ip.id)
        end))

  scope :items, -> { joins(:model).where(models: { type: 'Model' }) }
  scope :licenses, -> { joins(:model).where(models: { type: 'Software' }) }

  ####################################################################

  def type
    # case model.type
    # FIXME database consistency: there are items with model_id as nil
    case model.try :type
    when 'Model', nil
      'Item'
    when 'Software'
      'License'
    else
      raise 'Unknown type'
    end
  end

  def license?
    type == 'License'
  end

  def to_s
    "#{model.name} #{inventory_code}"
  end

  def label_for_audits
    "#{model.name} #{inventory_code}"
  end

  # an item is in stock if it's not handed over or
  # it's not assigned to an approved reservation
  def in_stock?
    if parent_id
      parent.in_stock?
    else
      reservations.signed.empty? and reservations.where(returned_date: nil).empty?
    end
  end

  ####################################################################
  # TODO include Statistic module

  def location
    return if license?
    "#{room.building} #{room} #{shelf}"
  end

  def current_location
    current_location = []
    if inventory_pool and owner != inventory_pool
      current_location.push inventory_pool.to_s
    end
    if u = current_borrower
      current_location.push \
        "#{u.firstname} #{u.lastname} #{_('until')} #{I18n.l(current_return_date)}"
    else
      current_location.push location
    end
    current_location.compact.join(', ')
  end

  def current_borrower
    reservation = current_reservation
    reservation.user if reservation
  end

  def current_delegated_borrower
    reservation = current_reservation
    reservation.delegated_user if reservation
  end

  def current_return_date
    reservation = current_reservation
    reservation.end_date if reservation
  end

  # TODO: statistics
  def latest_borrower
    reservation = latest_reservation
    reservation.user if reservation
  end

  # TODO: statistics
  def latest_take_back_manager
  end

  ####################################################################

  def update_children_attributes
    children.each do |child|
      update_child_attributes(child)
    end
  end

  ####################################################################

  # overriding attribute setter
  def retired=(v)
    if v.is_a? Date
      self[:retired] = v
    elsif [true, 'true'].include? v
      if retired?
        # we keep the existing stored date
      else
        self[:retired] = Time.zone.today
      end
    else
      self[:retired] = nil
    end
  end

  # overriding attribute setter
  def price=(v)
    if v.is_a? String
      if v.gsub(/\d/, '').last == '.'
        v.gsub!(/[^\d\.]/, '')
      else
        v.gsub!(/[^\d,]/, '')
        v.tr!(',', '.')
      end
    end
    self[:price] = v
  end

  ####################################################################

  # overriding association setter
  def supplier_with_params=(v)
    self.supplier_without_params =
      if v.is_a? Hash
        unless v[:id].blank?
          Supplier.find v[:id]
        end
        # otherwise, item.supplier is set to nil automatically
      else
        v
      end
  end

  alias_method :supplier_without_params=, :supplier=
  alias_method :supplier=, :supplier_with_params=

  # overriding association setter
  def owner_with_params=(v)
    self.owner_without_params = if v.is_a? Hash
                                  InventoryPool.find(v[:id]) unless v[:id].blank?
                                else
                                  v
                                end
  end

  alias_method :owner_without_params=, :owner=
  alias_method :owner=, :owner_with_params=

  # overriding association setter
  def inventory_pool_with_params=(v)
    self.inventory_pool_without_params = if v.is_a? Hash
                                           unless v[:id].blank?
                                             InventoryPool.find(v[:id])
                                           end
                                         else
                                           v
                                         end
  end

  alias_method :inventory_pool_without_params=, :inventory_pool=
  alias_method :inventory_pool=, :inventory_pool_with_params=

  ####################################################################

  private

  def get_model_manufacturer
    if self.model.nil? or self.model.name.blank?
      # FIXME: using model.try because database inconsistency
      'UNKNOWN' if self.model.try(:manufacturer).blank?
    else
      unless self.model.manufacturer.blank?
        self.model.manufacturer.gsub(/\"/, '""')
      end
    end
  end

  def get_categories(global = false)
    categories = []
    unless global
      # FIXME: using model.try because database inconsistency
      unless self.model.try(:categories).nil? or self.model.categories.count == 0
        self.model.categories.each do |c|
          categories << c.name
        end
      end
    end
    categories
  end

  def get_fields
    # we use select instead of multiple where because we need to keep the sorting
    # we exclude what is already hardcoded before (model_id as product and version)
    Field.all.select do |f|
      [nil, type.downcase].include?(f.data['target_type']) \
        and not ['model_id'].include?(f.data['form_name'])
    end.sort_by do |f|
      [Field::GROUPS_ORDER.index(f.data['group']) || 999, f.position]
    end.group_by { |f| f.data['group'] }.values.flatten
  end

  # TODO: has_one/has_many
  def latest_reservation
    reservations.where.not(returned_date: nil).order('returned_date').last
  end

  def validates_package
    if parent_id
      if parent.nil?
        errors.add(:base,
                   _("The parent item doesn't exist (parent_id: %d)") % parent_id)
      elsif model.is_package?
        errors.add(:base, _('A package cannot be nested to another package'))
      end
    else
      unless children.empty? or model.is_package
        errors.add(:base, _('A package item must belong to a package model'))
      end

      if model.is_package? and !retired.nil?
        children.each do |item|
          item.update_attributes(parent: nil)
        end
      end
    end
  end

  def validates_changes
    unless reservations.empty?
      if model_id_changed?
        errors.add(:base,
                   _('The model cannot be changed because ' \
                     'the item is used in contracts already.'))
      end
    end
    unless in_stock?
      if inventory_pool_id_changed?
        errors.add(:base,
                   _('The responsible inventory pool cannot be changed because ' \
                     "it's not returned yet or has already been assigned " \
                     'to a contract line.'))
      end
      unless retired.nil?
        errors.add(:base,
                   _("The item cannot be retired because it's not returned yet " \
                     'or has already been assigned to a contract line.'))
      end
    end
  end

  def update_child_attributes(item)
    item.inventory_pool = self.inventory_pool
    item.room = self.room
    item.responsible = self.responsible
    item.last_check = self.last_check
    item.properties[:ankunftsdatum] = self.properties[:ankunftsdatum]
    item.save
  end

  def check_child(child)
    if child.model.is_package?
      raise _('A package cannot be nested to another package')
    end
  end

end
