class Accessory < ApplicationRecord

  belongs_to :model, inverse_of: :accessories
  has_and_belongs_to_many :inventory_pools

  # TODO: - a manager can only create if the required accessory doesn't yet exist,
  # - update and delete are available only if
  #   no other inventory pool is also associated.
  # - modifying the model, if a related item is handed over,
  #   a warning has to be displayed

  # - the admin defines the accessories for the given model
  # - when the admin assigns the first item of the given model
  #   to an inventory_pool,
  # then all accessories_inventory_pools assiociations are automatically generated

  # TODO: 13** implement quantity attribute

  validates_presence_of :name

  def inventory_pool_toggle=(val)
    ip_id = val.split(',')[1]
    ip = InventoryPool.find(ip_id)
    toggle_val = val.split(',')[0]

    if toggle_val == '1' and not self.inventory_pool_ids.include?(ip_id)
      self.inventory_pools = self.inventory_pools + [ip]
    else
      self.inventory_pools = self.inventory_pools - [ip]
    end
  end

  attr_writer :is_deletable

  def to_s
    name
  end

  def label_for_audits
    name
  end

  def active_in?(inventory_pool)
    inventory_pools.include? inventory_pool
  end
end
