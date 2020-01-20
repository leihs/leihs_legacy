class Borrow::AvailabilityController < Borrow::ApplicationController

  def show
    model = current_user.models.borrowable.find params[:model_id]
    inventory_pool = current_user.inventory_pools.find params[:inventory_pool_id]
    @availability =
      {
        id: "#{model.id}-#{current_user.id}-#{inventory_pool.id}",
        changes: \
        model.availability_in(inventory_pool).available_total_quantities,
        total_borrowable: \
        model.total_borrowable_items_for_user_and_pool(
          current_user,
          inventory_pool,
          ensure_non_negative: true
        ),
        inventory_pool_id: inventory_pool.id,
        model_id: model.id
      }
  end

  def booking_calendar_availability
    model = Model.find(model_id_param)
    ip = InventoryPool.find(inventory_pool_id_param)
    user = User.find(user_id_param)
    reservations = Reservation.find(reservation_ids_param)
    presenter = Borrow::BookingCalendar.new(ip,
                                            model,
                                            user,
                                            start_date_param,
                                            end_date_param,
                                            reservations)

    respond_with_presenter(presenter)
  end

  def total_borrowable_quantities
    model = Model.find(model_id_param)
    inventory_pools = InventoryPool.find(inventory_pool_ids_param)
    result = inventory_pools.map do |inventory_pool|
      {
        inventory_pool_id: inventory_pool.id,
        total_borrowable: \
        model.total_borrowable_items_for_user_and_pool(
          current_user,
          inventory_pool,
          ensure_non_negative: true
        )
      }
    end

    render(json: result) and return
  end

  private

  def user_id_param
    params.fetch(:user_id, current_user.id)
  end

  def inventory_pool_id_param
    params.require(:inventory_pool_id)
  end

  def inventory_pool_ids_param
    params.require(:inventory_pool_ids)
  end

  def model_id_param
    params.require(:model_id)
  end

  def start_date_param
    params.fetch(:start_date, Date.today)
  end

  def end_date_param
    params.require(:end_date)
  end

  def reservation_ids_param
    params.fetch(:reservation_ids, [])
  end
end
