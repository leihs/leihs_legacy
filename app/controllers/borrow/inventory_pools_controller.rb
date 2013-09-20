class Borrow::InventoryPoolsController < Borrow::ApplicationController
  
  def index
    @inventory_pools = current_user.inventory_pools.sort_by {|ip| ip.name}
    @suspended_inventory_pools = @inventory_pools.select {|ip| current_user.access_right_for(ip).suspended?}
  end
end
