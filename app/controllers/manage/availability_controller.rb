class Manage::AvailabilityController < Manage::ApplicationController

  before_action :before_action_hook

  def before_action_hook
    @models = Model.where id: params[:model_ids]
    head :bad_request and return if @models.blank?
    @availabilities = []
  end

  def index
    user = current_inventory_pool.users.find params[:user_id]
    @models.each do |model|
      @availabilities.push \
        id: "#{model.id}-#{user.id}-#{current_inventory_pool.id}",
        changes: \
          model
            .availability_in(current_inventory_pool)
            .available_total_quantities,
        total_rentable: \
          model
            .items
            .where(inventory_pool_id: current_inventory_pool)
            .unretired
            .borrowable
            .count,
        inventory_pool_id: current_inventory_pool.id,
        model_id: model.id
    end
  end

  def in_stock
    @models.each do |model|
      entitled_in_groups = \
        Entitlement
        .joins(:entitlement_group)
        .where(
          entitlement_groups: { inventory_pool_id: current_inventory_pool.id }
        )
        .where(model_id: model.id)
        .map(&:quantity)
        .reduce(&:+)
      entitled_in_groups ||= 0

      @availabilities.push \
        id: "#{model.id}-#{current_inventory_pool.id}",
        total_rentable: \
          model
            .items
            .where(inventory_pool_id: current_inventory_pool)
            .borrowable
            .unretired
            .count,
        in_stock: \
          model
            .items
            .where(inventory_pool_id: current_inventory_pool)
            .borrowable
            .unretired
            .in_stock
            .count,
        entitled_in_groups: entitled_in_groups,
        inventory_pool_id: current_inventory_pool.id,
        model_id: model.id
    end
    render :index
  end

end
