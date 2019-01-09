class Manage::OrdersController < Manage::ApplicationController

  # NOTE overriding super controller
  private def required_manager_role
    require_role :group_manager, current_inventory_pool
  end

  def index
    respond_to do |format|
      format.html
      format.json do
        @orders = Order.filter2(params, nil, current_inventory_pool)

        if params[:order_by_created_at_group_by_user]
          @orders = @orders.select('orders.*').select(
            <<-SQL
              first_value(orders.created_at)
              over (partition by orders.user_id order by orders.created_at desc)
              as newest_created_at_per_user
            SQL
          ).reorder('newest_created_at_per_user desc, user_id, created_at desc')
        end

        set_pagination_header @orders, disable_total_count: (
          params[:disable_total_count] == 'true' ? true : false
        )
      end
    end
  end

  def edit
    @order = Order.find(id_param)
    @user = @order.user
    @group_ids = @user.entitlement_group_ids
    add_visitor(@user)
    @reservations = @order.reservations
    @models = @reservations.map(&:model).select { |m| m.type == 'Model' }.uniq
    @software = @reservations.map(&:model).select { |m| m.type == 'Software' }.uniq
    @items = \
      @reservations.where.not(item_id: nil)
      .map(&:item)
      .select { |i| i.type == 'Item' }
    @grouped_lines = @reservations.group_by { |g| [g.start_date, g.end_date] }
    @grouped_lines.each_pair do |k, reservations|
      @grouped_lines[k] = \
        reservations.sort_by { |line| line.model.name }.group_by(&:model)
    end
    @start_date = @order.min_date
    @end_date = @order.max_date
  end

  def update
    @order = Order.find(id_param)
    begin
      @order.update_attributes!(purpose: purpose_param)
      render json: @order, status: 200
    rescue => e
      render plain: e.message, status: 500
    end
  end

  def swap_user
    @order = Order.find(id_param)
    Order.transaction do
      begin
        @order.update_attributes!(user_id: user_id_param)
        @order.reservations.each do |reservation|
          reservation.update_attributes!(
            user_id: user_id_param,
            delegated_user_id: delegated_user_id_param
          )
        end
        head :ok
      rescue => e
        render json: e.message, status: :bad_request
      end
    end
  end

  def approve
    @order = Order.find(id_param)

    if @order.approve(params[:comment], true, current_user, force_param)
      respond_to do |format|
        format.json { render json: true, status: 200 }
      end
    else
      errors = @order.errors.full_messages.uniq.join("\n")
      respond_to do |format|
        format.json { render plain: errors, status: 500 }
      end
    end
  end

  def reject
    @order = Order.find(id_param)

    if request.post? \
      and params[:comment] \
      and @order.reject(params[:comment], current_user)
      respond_to do |format|
        format.json { render json: true, status: 200 }
        format.html do
          redirect_to manage_daily_view_path,
                      flash: { success: _('Order rejected') }
        end
      end
    else
      errors = @order.errors.full_messages.uniq.join("\n")
      respond_to do |format|
        format.json { render plain: errors, status: 500 }
        format.html { render :edit }
      end
    end
  end

  private

  def id_param
    params.require(:id)
  end

  def force_param
    params.fetch(:force, false)
  end

  def purpose_param
    params.require(:purpose)
  end

  def user_id_param
    params.require(:user_id)
  end

  def delegated_user_id_param
    params.fetch(:delegated_user_id, nil)
  end
end
