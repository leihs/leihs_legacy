class Manage::ReservationsController < Manage::ApplicationController

  private

  # NOTE overriding super controller
  def required_manager_role
    closed_actions = [:assign, :assign_or_create, :remove_assignment, :take_back]
    if closed_actions.include?(action_name.to_sym)
      super
    else
      require_role :group_manager, current_inventory_pool
    end
  end

  public

  def index
    @reservations = Reservation.filter params, current_inventory_pool
  end

  def update
    # TODO: params.require(:reservation).permit(:item_id, :model_id, :option_id,
    # :quantity, :start_date, :end_date)
    params[:reservation].delete(:contract_id)

    @reservation = current_inventory_pool.reservations.find(params[:line_id])
    unless @reservation.update_attributes(params[:reservation])
      render status: :bad_request,
             text: @reservation.errors.full_messages.uniq.join(', ')
    end
  end

  def create
    user = User.find(params[:user_id])
    inventory_pool = InventoryPool.find(params[:inventory_pool_id])

    begin
      Order.transaction do
        record = if params[:model_id]
                   current_inventory_pool.models.find(params[:model_id])
                 else
                   current_inventory_pool.options.find(params[:option_id])
                 end
        # accomodate hand over and edit order
        order = Order.find_by(id: params[:order_id])
        @reservation = create_reservation(user,
                                          order.try(&:id),
                                          inventory_pool,
                                          (order.try(&:state) or :approved),
                                          record,
                                          1,
                                          params[:start_date],
                                          params[:end_date])
      end
    rescue => e
      render status: :bad_request, plain: e
    end
  end

  def create_for_template
    user = User.find(params[:user_id])
    order = Order.find_by(id: params[:order_id])

    @reservations = []
    ApplicationRecord.transaction do
      template = Template.find(params[:template_id])
      template.model_links.each do |link|
        next unless current_inventory_pool.models.exists?(id: link.model_id)
        link.quantity.times do
          @reservations.push \
            create_reservation(user,
                               order.try(&:id),
                               current_inventory_pool,
                               (order.try(&:state) or :approved),
                               current_inventory_pool.models.find(link.model_id),
                               1,
                               params[:start_date],
                               params[:end_date])
        end
      end
    end
    if @reservations.empty?
      render json: 'No available models for this template and inventory pool!',
             status: :bad_request
    end
  end

  def destroy
    begin
      current_inventory_pool
        .reservations
        .where(id: (params[:line_id] || params[:line_ids]))
        .destroy_all
    rescue => e
      Rails.logger.error e
    ensure
      render status: :ok, json: { id: params[:line_id] }
    end
  end

  def change_time_range(
    reservations = current_inventory_pool.reservations.find(params[:line_ids]),
    start_date = params[:start_date].try { |x| Date.parse(x) },
    end_date = params[:end_date].try { |x| Date.parse(x) } || Date.tomorrow)
    begin
      reservations.each do |line|
        line.update_time_line \
          (start_date || line.start_date),
          end_date,
          current_user
      end
      render status: :ok, json: reservations
    rescue => e
      render status: :bad_request, plain: e
    end
  end

  def assign
    item = \
      current_inventory_pool
      .items
      .find_by('UPPER(inventory_code) = ?', params[:inventory_code].upcase)
    line = current_inventory_pool.reservations.approved.find params[:id]

    if item and line and line.model_id == item.model_id
      unless line.update_attributes(item: item)
        @error = { message: line.errors.full_messages.uniq.join(', ') }
      end
    else
      unless params[:inventory_code].blank?
        @error =
          if item and line and line.model_id != item.model_id
            { message: \
                _('The inventory code %s is not valid for this model') % \
                params[:inventory_code] }
          elsif line
            { message: \
                _("The item with the inventory code '%s' was not found") % \
                params[:inventory_code] }
          elsif item
            { message: _('The line was not found') }
          else
            { message: _('Assigning the inventory code fails') }
          end
      end
      line.update_attributes(item: nil)
    end

    if @error.blank?
      render status: :ok, json: line
    else
      render status: :bad_request, json: @error
    end
  end

  # used in hand over
  def assign_or_create
    @user = current_inventory_pool.users.find(params[:user_id])

    item = \
      current_inventory_pool
      .items
      .where('UPPER(inventory_code) = ?', code_param.upcase)
      .first

    model = find_model(item)
    option = find_option unless model

    line, error = create_new_line_or_assign(@user,
                                            model,
                                            item,
                                            option)

    if error.blank?
      render status: :ok, json: line
    else
      render plain: error, status: :bad_request
    end
  end

  def remove_assignment
    line = current_inventory_pool.reservations.approved.find params[:id]
    line.update_attributes(item_id: nil)
    head :ok
  end

  def take_back
    returned_quantity = params[:returned_quantity]
    reservations = current_inventory_pool.reservations.find(params[:ids])

    begin
      ApplicationRecord.transaction do
        if returned_quantity
          returned_quantity.each_pair do |k, v|
            line = reservations.detect { |l| l.id == k }
            next unless line and Integer(v) < line.quantity
            new_line = line.dup
            new_line.quantity -= Integer(v)
            new_line.save!
            line.update_attributes!(quantity: Integer(v))
          end
        end

        reservations.each do |l|
          l.update_attributes!(returned_date: Time.zone.today,
                               returned_to_user_id: current_user.id)

          if l.last_closed_reservation_of_contract?
            l.contract.update_attributes!(state: :closed)
          end
        end

        head :ok
      end
    rescue => e
      render status: :bad_request, plain: e.message
    end
  end

  # for hand over
  def swap_user
    user = current_inventory_pool.users.find params[:user_id]
    reservations = current_inventory_pool.reservations.where(id: params[:line_ids])

    ApplicationRecord.transaction do
      begin
        ####################################################################
        # Create new orders with the same purpose and pool, but with the
        # new user. It's a copy of the older user's orders but with the
        # new user, so to say. If there is at least one such pool order,
        # then pack all the orders inside a new customer order for the
        # new user.
        ####################################################################
        orders = reservations.map(&:order).compact.uniq

        if orders.presence
          customer_order = CustomerOrder.create!(
            user: user,
            purpose: orders.map(&:purpose).join('; ')
          )
        end

        reservations.group_by(&:order).each_pair do |order, lines|
          if order
            new_order = Order.create!(user: user,
                                      inventory_pool: order.inventory_pool,
                                      customer_order: customer_order,
                                      state: order.state,
                                      purpose: order.purpose)
          end

          lines.each do |line|
            delegated_user = if user.delegation?
                               if user.delegated_users.include? line.delegated_user
                                 line.delegated_user
                               else
                                 user.delegator_user
                               end
                             end

            line.update_attributes!(user: user,
                                    delegated_user: delegated_user,
                                    order: new_order || nil)
          end
        end

        head :ok
      rescue => e
        render(status: :bad_request, plain: e.message)
        raise ActiveRecord::Rollback
      end
    end
  end

  def swap_model
    reservations = current_inventory_pool.reservations.where(id: params[:line_ids])
    model = Model.find(params[:model_id])
    ApplicationRecord.transaction do
      reservations.each do |line|
        line.update_attributes(model: model, item_id: nil)
      end
    end
    if reservations.all?(&:valid?)
      render json: reservations
    else
      head :bad_request
    end
  end

  def print
    @reservations = current_inventory_pool.reservations.where(id: params[:ids])
    @user = @reservations.first.user
    @delegated_user = @reservations.first.delegated_user

    case params[:type]
    when 'value_list'
      render 'documents/reservations', layout: 'print'
    when 'picking_list'
      render 'documents/picking_list', layout: 'print'
    end
  end

  private

  def code_param
    params[:code]
  end

  def model_group_id_param
    params[:model_group_id]
  end

  def model_id_param
    params[:model_id]
  end

  def option_id_param
    params[:model_id]
  end

  def quantity_param
    Integer(params[:quantity].presence || 1)
  end

  def start_date_param
    params[:start_date].try { |x| Date.parse(x) } || Time.zone.today
  end

  def end_date_param
    params[:end_date].try { |x| Date.parse(x) } || Date.tomorrow
  end

  def line_ids_param
    params[:line_ids]
  end

  def find_model(item)
    if not code_param.blank?
      item.model if item
    elsif model_group_id_param
      # TODO: scope current_inventory_pool ?_param
      Template.find(model_group_id_param)
    elsif model_id_param
      current_inventory_pool.models.find(model_id_param)
    end
  end

  def find_option
    if option_id_param
      option = current_inventory_pool.options.find(option_id_param)
    end
    option || \
      current_inventory_pool
        .options
        .where(inventory_code: code_param)
        .first
  end

  def create_reservation(user,
                         order_id,
                         inventory_pool,
                         status,
                         record,
                         quantity,
                         start_date,
                         end_date)
    if record.is_a? Model
      reservation = user.item_lines.new(model: record)
    elsif record.is_a? Option
      reservation = user.option_lines.new(option: record)
    end
    reservation.order_id = order_id
    reservation.inventory_pool = inventory_pool
    reservation.status = status
    reservation.quantity = Integer(quantity)
    reservation.start_date = \
      start_date.try { |x| Date.parse(x) } || Time.zone.today
    reservation.end_date = end_date.try { |x| Date.parse(x) } || Date.tomorrow

    # NOTE we need to store because the availability reads the persisted
    # reservations (as running_reservations)
    # then we rollback on failing conditions
    Reservation.transaction do
      reservation.save!
      if (group_manager? and not lending_manager?) and not reservation.available?
        raise _('Not available')
      else
        reservation
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def create_new_line_or_assign(user, model, item, option)
    error = nil
    line = nil

    ApplicationRecord.transaction do
      begin
        # error if item already assigned to some approved reservation of the user
        if item && line = \
            user
            .reservations
            .where(inventory_pool: current_inventory_pool)
            .approved
            .find_by(item_id: item.id)
          error = \
            _('%s is already assigned to this contract') % item.inventory_code
        # create new line or assign
        elsif model
          # try to assign for (selected)line_ids first
          if line_ids_param and code_param
            line = \
              user
              .reservations
              .where(inventory_pool: current_inventory_pool)
              .approved
              .where(id: line_ids_param,
                     model_id: item.model.id,
                     item_id: nil).first
          end
          # try to assign to approved reservations of the customer
          if code_param
            line ||= \
              user
                .reservations
                .approved
                .where(inventory_pool: current_inventory_pool)
                .where(model_id: model.id, item_id: nil)
                .order(:id)
                .first
          end
          # add new line
          line ||= \
            ItemLine.create(
              status: :approved,
              user: user,
              model: model,
              inventory_pool: current_inventory_pool,
              start_date: start_date_param,
              end_date: end_date_param
            )
          if model_group_id_param.nil? \
            and item \
            and line \
            and not line.update_attributes!(item: item)
            error = line.errors.values.join
          end
        elsif option
          if line = \
              user
              .reservations
              .approved
              .where(inventory_pool: current_inventory_pool)
              .where(option_id: option.id,
                     start_date: start_date_param,
                     end_date: end_date_param).first
            line.quantity += quantity_param
            line.save
          elsif not line = \
            OptionLine.create(
              user: user,
              status: :approved,
              inventory_pool: current_inventory_pool,
              option: option,
              quantity: quantity_param,
              start_date: start_date_param,
              end_date: end_date_param
            )
            error = _('The option could not be added')
          end
        else
          error =
            if code
              _('A model for the Inventory Code / ' \
                "Serial Number '%s' was not found") % \
               code_param
            elsif model_id_param
              _("A model with the ID '%s' was not found") % \
                model_id_param
            elsif model_group_id_param
              _("A template with the ID '%s' was not found") % \
                model_group_id_param
            end
        end
      rescue => e
        error = e.message
        raise ActiveRecord::Rollback
      end
    end

    [line, error]
  end
  # rubocop:enable Metrics/MethodLength
end
