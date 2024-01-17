class Entitlement < ApplicationRecord

  belongs_to :model, inverse_of: :entitlements
  belongs_to :entitlement_group, inverse_of: :entitlements
  delegate :inventory_pool, to: :entitlement_group

  validates_presence_of :model, :entitlement_group, :quantity
  validates_numericality_of :quantity, only_integer: true, greater_than: 0
  validates_uniqueness_of :entitlement_group_id, scope: :model_id

  scope :with_generals, lambda {|model_ids: nil, inventory_pool_id: nil|
    find_by_sql query(model_ids: model_ids,
                      inventory_pool_id: inventory_pool_id)
  }

  # returns a hash as {entitlement_group_id => quantity}
  # like {nil => 10, 41 => 3, 42 => 6, ...}
  def self.hash_with_generals(inventory_pool,
                              model,
                              entitlement_groups = nil,
                              sanitize_invalid_entitled_quantity: false)
    entitlements = with_generals(model_ids: [model.id],
                                 inventory_pool_id: inventory_pool.id)

    if entitlement_groups
      entitlement_group_ids = entitlement_groups.map { |eg| eg.try(:id) }
      entitlements = entitlements.select do |entitlement|
        entitlement_group_ids.include? entitlement.entitlement_group_id
      end
    end


    result = Hash[
      entitlements.map do |e|
        quantity = if sanitize_invalid_entitled_quantity # case when entitled quantity is higher than actually available total quantity
                     if e.entitlement_group_id.nil?
                       e.quantity < 0 ? 0 : e.quantity
                     else
                       [e.max_possible_quantity, e.quantity].min
                     end
                   else
                     e.quantity
                   end
        [e.entitlement_group_id, quantity]
      end
    ]

    if missing_general_group_id?(result)
      result[EntitlementGroup::GENERAL_GROUP_ID] = 0
    end

    result
  end

  def self.missing_general_group_id?(h)
    h.empty? or not h.key?(EntitlementGroup::GENERAL_GROUP_ID)
  end

  def self.negative_general_quantity?(h)
    h[EntitlementGroup::GENERAL_GROUP_ID].negative?
  end

  def self.query(model_ids: nil, inventory_pool_id: nil)
    # NOTE: this query is duplicated in new leihs-borrow !!
    <<-SQL
      SELECT model_id,
             entitlement_groups.inventory_pool_id,
             entitlement_group_id,
             quantity
      FROM entitlements
      INNER JOIN entitlement_groups
        ON entitlements.entitlement_group_id = entitlement_groups.id
      WHERE TRUE
     #{"AND model_id IN ('#{model_ids.join('\', \'')}') " if model_ids}
     #{"AND entitlement_groups.inventory_pool_id = \'#{inventory_pool_id}\' " if inventory_pool_id}

      UNION

      SELECT model_id,
             inventory_pool_id,
             NULL as entitlement_group_id,
             (COUNT(i.id) - COALESCE(
               (SELECT SUM(quantity)
                FROM entitlements AS es
                INNER JOIN entitlement_groups
                  ON entitlement_groups.id = es.entitlement_group_id
                WHERE es.model_id = i.model_id
                AND entitlement_groups.inventory_pool_id = i.inventory_pool_id
                GROUP BY entitlement_groups.inventory_pool_id, es.model_id),
                0)
             ) as quantity
      FROM items AS i
      WHERE i.retired IS NULL AND i.is_borrowable = true
        AND i.parent_id IS NULL
     #{"AND i.model_id IN ('#{model_ids.join('\', \'')}') " if model_ids}
     #{"AND i.inventory_pool_id = \'#{inventory_pool_id}\' " if inventory_pool_id}
      GROUP BY i.inventory_pool_id, i.model_id
    SQL
  end

  def entitled_quantity_in_other_groups
    qty = \
      Entitlement
      .joins(:entitlement_group)
      .where(entitlement_groups: {
        inventory_pool_id: entitlement_group.inventory_pool.id
      })
      .where(model_id: model.id)
      .where.not(id: id)
      .map(&:quantity)
      .reduce(&:+)
    qty || 0
  end

  def max_possible_quantity
    model
      .borrowable_items
      .where(inventory_pool_id: entitlement_group.inventory_pool.id)
      .size
  end

  def max_possible_unentitled_quantity
    max_possible_quantity - entitled_quantity_in_other_groups
  end

end
