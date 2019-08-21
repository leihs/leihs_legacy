class Borrow::CustomerOrdersController < Borrow::ApplicationController

  before_action only: [:current, :timed_out] do
    @grouped_and_merged_lines = \
      Contract.grouped_and_merged_lines(current_user.reservations.unsubmitted)
    @models = current_user.reservations.unsubmitted.map(&:model).uniq
    @inventory_pools = \
      current_user.reservations.unsubmitted.map(&:inventory_pool).uniq
  end

  def index
    respond_to do |format|
      format.html do
        @grouped_and_merged_lines = \
          Contract.grouped_and_merged_lines current_user.reservations.submitted
      end
    end
  end

  def current
    @inventory_pools_for_calendar = inventory_pools_for_calendar(@inventory_pools)
  end

  def submit
    Order.transaction do
      begin
        current_user
          .reservations
          .unsubmitted
          .group_by(&:inventory_pool_id)
          .each_pair do |inventory_pool_id, reservations|
          inventory_pool = InventoryPool.find(inventory_pool_id)
          order = Order.create!(user: current_user,
                                inventory_pool: inventory_pool,
                                purpose: purpose_param,
                                state: :submitted)

          reservations.each do |reservation|
            if mrt = app_settings.maximum_reservation_time
              if (reservation.end_date - reservation.start_date) >= mrt
                raise [_('Maximum reservation time is restricted to'),
                       mrt,
                       n_('day', 'days', mrt)].join(' ')
              end
            end

            if reservation.user.delegation?
              reservation.delegated_user = \
                reservation.user.delegated_users.find(user_session.user_id)
            end

            reservation.order = order

            unless reservation.submittable?
              raise reservation.errors.full_messages.uniq.join(', ')
            end

            reservation.status = :submitted

            unless reservation.approvable?
              raise reservation.errors.full_messages.uniq.join(', ')
            end

            reservation.save!
          end

          order.reload
          order.send_submitted_notification
          order.send_received_notification
        end
        flash[:notice] = _('Your order has been successfully submitted, ' \
                           'but is NOT YET APPROVED.')
        redirect_to borrow_root_path
      rescue => e
        Rails.logger.warn e
        flash[:error] = e.message
        redirect_to borrow_current_order_path
        raise ActiveRecord::Rollback
      end
    end
  end

  def remove
    current_user.reservations.unsubmitted.each(&:destroy)
    redirect_to borrow_root_path
  end

  def remove_reservations(line_ids = params[:line_ids])
    reservations = current_user.reservations.unsubmitted.find(line_ids)
    reservations.each(&:destroy!)
    redirect_to borrow_current_order_path
  end

  def timed_out
    flash[:error] =  \
      _('%d minutes passed. The items are not reserved for you any more!') \
      % app_settings.timeout_minutes
    @timed_out = true
    @inventory_pools_for_calendar = inventory_pools_for_calendar(@inventory_pools)
    render :current
  end

  def delete_unavailables
    current_user.reservations.unsubmitted.each { |l| l.delete unless l.available? }
    redirect_to \
      borrow_current_order_path,
      flash: { success: _('Your order has been modified. ' \
                          'All reservations are now available.') }
  end

  private

  def inventory_pools_for_calendar(inventory_pools)
    inventory_pools.map do |ip|
      { inventory_pool: ip,
        workday: ip.workday,
        holidays: \
          ip.holidays.where('CURRENT_DATE <= end_date').order(:end_date) }
    end
  end

  def purpose_param
    params.require(:purpose)
  end

end
