class Manage::SuspensionsController < Manage::ApplicationController

  def index
    @suspensions = Suspension.where(inventory_pool_id: current_inventory_pool.id)
  end

end

