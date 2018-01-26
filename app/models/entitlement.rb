class Entitlement < ApplicationRecord
  audited

  belongs_to :model, inverse_of: :entitlements
  belongs_to :inventory_pool
  belongs_to :entitlement_group, inverse_of: :entitlements

  validates_presence_of :model, :inventory_pool, :entitlement_group, :quantity
  validates_numericality_of :quantity, only_integer: true, greater_than: 0
  validates_uniqueness_of :entitlement_group_id,
                          scope: [:model_id, :inventory_pool_id]

  scope :with_generals, lambda {|model_ids: nil, inventory_pool_id: nil|
    find_by_sql query(model_ids: model_ids,
                      inventory_pool_id: inventory_pool_id)
  }

  # returns a hash as {entitlement_group_id => quantity}
  # like {nil => 10, 41 => 3, 42 => 6, ...}
  def self.hash_with_generals(inventory_pool,
                              model,
                              entitlement_groups = nil,
                              ensure_non_negative_general: false)
    # NOTE: `ensure_non_negative_general` is necessary for the borrow
    # booking calendar. Negative quantity makes no sense there and leads to buggy
    # behaviour. How does the negative value come to existence and if it is a
    # desired feature remains questionable.
    entitlements = with_generals(model_ids: [model.id],
                                 inventory_pool_id: inventory_pool.id)

    if entitlement_groups
      entitlement_group_ids = entitlement_groups.map { |eg| eg.try(:id) }
      entitlements = entitlements.select do |entitlement|
        entitlement_group_ids.include? entitlement.entitlement_group_id
      end
    end

    result = Hash[entitlements.map { |e| [e.entitlement_group_id, e.quantity] }]
    if missing_general_group_id?(result) or
        (negative_general_quantity?(result) and ensure_non_negative_general)
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
    <<-SQL
      SELECT model_id,
             inventory_pool_id,
             entitlement_group_id,
             quantity
      FROM entitlements
      WHERE TRUE
     #{"AND model_id IN ('#{model_ids.join('\', \'')}') " if model_ids}
     #{"AND inventory_pool_id = \'#{inventory_pool_id}\' " if inventory_pool_id}

      UNION

      SELECT model_id,
             inventory_pool_id,
             NULL as entitlement_group_id,
             (COUNT(i.id) - COALESCE((SELECT SUM(quantity)
                                      FROM entitlements AS p
                                      WHERE p.model_id = i.model_id
                                      AND p.inventory_pool_id = i.inventory_pool_id
                                      GROUP BY p.inventory_pool_id, p.model_id),
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

  def label_for_audits
    "#{model.try(&:name)} - #{entitlement_group.try(&:name)}"
  end
end
