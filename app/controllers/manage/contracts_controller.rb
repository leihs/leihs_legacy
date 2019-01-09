class Manage::ContractsController < Manage::ApplicationController

  before_action do
    if params[:id]
      @contract = Contract.find(params[:id])
    end
    @user = current_inventory_pool.users.find(params[:user_id]) if params[:user_id]
  end

  private

  # NOTE overriding super controller
  def required_manager_role
    closed_actions = [:create]
    if closed_actions.include?(action_name.to_sym)
      super
    else
      require_role :group_manager, current_inventory_pool
    end
  end

  public

  ######################################################################

  def index
    respond_to do |format|
      format.html
      format.json do
        @contracts = Contract.filter2(params,
                                      nil,
                                      current_inventory_pool,
                                      paginate: false)
        count = Contract.from(@contracts).count
        @contracts = @contracts.default_paginate(params).order('created_at DESC')
        set_pagination_header(
          @contracts,
          disable_total_count: (
            params[:disable_total_count] == 'true' ? true : false
          ),
          custom_count: (
            params[:global_contracts_search] == 'true' ? count : nil
          )
        )
      end
    end
  end

  def show
    @contract = Contract.find(params[:id])
    @user = @contract.user
    @delegated_user = @contract.delegated_user
    render 'documents/contract', layout: 'print'
  end

  def value_list
    @user = @contract.user
    @delegated_user = @contract.delegated_user
    render 'documents/value_list', layout: 'print'
  end

  def picking_list
    @user = @contract.user
    @delegated_user = @contract.delegated_user
    render 'documents/picking_list', layout: 'print'
  end

  def create
    reservations = \
      @user
      .reservations
      .approved
      .where(inventory_pool: current_inventory_pool)
      .find(line_ids_param)

    ApplicationRecord.transaction do
      begin
        @contract = Contract.sign!(current_user,
                                   current_inventory_pool,
                                   @user,
                                   reservations,
                                   params[:purpose],
                                   params[:note],
                                   params[:delegated_user_id])

        render json: @contract.to_json
      rescue => e
        render status: :bad_request, plain: e.message
      end
    end
  end

  def swap_user
    order = current_inventory_pool.orders.find params[:id]
    user = current_inventory_pool.users.find(params[:user_id]) if params[:user_id]
    delegated_user = if params[:delegated_user_id]
                       current_inventory_pool \
                         .users
                         .find(params[:delegated_user_id])
                     end
    reservations = order.reservations
    ApplicationRecord.transaction do
      reservations.each do |line|
        line.update_attributes(user: user, delegated_user: delegated_user)
      end
    end
    if reservations.all?(&:valid?)
      render \
        json: \
          user \
            .orders
            .find_by(status: order.status,
                     inventory_pool_id: current_inventory_pool).to_json
    else
      errors = reservations.flat_map { |line| line.errors.full_messages }
      render status: :bad_request, plain: errors.uniq.join(', ')
    end
  end

  private

  def line_ids_param
    params.require(:line_ids)
  end
end
