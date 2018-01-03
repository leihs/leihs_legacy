class Borrow::InventoryPoolsController < Borrow::ApplicationController

  def index
    inventory_pools = []
    inventory_pools.concat(
      @current_user.inventory_pools.with_borrowable_items.map { |ip| ip }
    )
    inventory_pools.concat(
      @current_user.contracts.map(&:inventory_pool)
    )
    uniq_inventory_pools = inventory_pools.uniq(&:id)

    @inventory_pools = uniq_inventory_pools.sort_by { |ip| ip.name.downcase }
  end
end
