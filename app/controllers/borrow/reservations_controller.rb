class Borrow::ReservationsController < Borrow::ApplicationController
  include Borrow::Concerns::CreateLines

  before_action only: [:create, :change_time_range] do
    @start_date = params[:start_date].try { |x| Date.parse(x) } || Time.zone.today
    @end_date = params[:end_date].try { |x| Date.parse(x) } || Date.tomorrow
    @inventory_pool = current_user.inventory_pools.find(params[:inventory_pool_id])

    @errors = []
    unless @inventory_pool.open_on?(@start_date)
      @errors << _('Inventory pool is closed on start date')
    end
    unless @inventory_pool.open_on?(@end_date)
      @errors << _('Inventory pool is closed on end date')
    end
    if @start_date < \
      Time.zone.today + @inventory_pool.workday.reservation_advance_days.days
      @errors << _('No orders are possible on this start date')
    end
    if @inventory_pool.workday.reached_max_visits.include? @start_date
      @errors << _('Booking is no longer possible on this start date')
    end
    if @inventory_pool.workday.reached_max_visits.include? @end_date
      @errors << _('Booking is no longer possible on this end date')
    end
  end

  def create
    model = current_user.models.borrowable.find(params[:model_id])

    unless quantity_available?(model, quantity_param)
      @errors << _('Item is not available in that time range')
    end

    if @errors.empty?
      begin
        ApplicationRecord.transaction do
          reservations = create_lines(
            model: model,
            quantity: quantity_param,
            status: :unsubmitted,
            inventory_pool: @inventory_pool,
            start_date: @start_date,
            end_date: @end_date,
            delegated_user_id: session[:delegated_user_id]
          )
          if reservations and reservations.all?(&:valid?)
            render status: :ok, json: reservations
          end
        end
      rescue => e
        render status: :bad_request, json: e.message
      end
    else
      render status: :bad_request, json: @errors.uniq.join(', ')
    end
  end

  def destroy
    begin
      ApplicationRecord.transaction do
        current_user
          .reservations
          .unsubmitted
          .find(params[:line_ids])
          .map(&:destroy!)
      end
      render status: :ok, json: {}
    rescue => e
      render status: :bad_request, json: e.message
    end
  end

  def change_time_range
    reservations = Reservation.find(params[:line_ids])
    if @errors.empty?
      begin
        reservations.each do |line|
          line.update_time_line(@start_date, @end_date, current_user)
          line.reload
        end
        render status: :ok, json: reservations
      rescue => e
        render status: :bad_request, plain: e
      end
    else
      render status: :bad_request, json: @errors.uniq.join(', ')
    end
  end

  private

  def quantity_param
    params.require(:quantity).to_i
  end

  def quantity_available?(model, quantity)
    model
      .availability_in(@inventory_pool)
      .maximum_available_in_period_summed_for_groups(
        @start_date,
        @end_date,
        current_user.entitlement_group_ids) \
   >= quantity
  end
end
