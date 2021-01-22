class Manage::UsersController < Manage::ApplicationController

  before_action do
    not_authorized! unless group_manager?

    if params[:access_right]
      @ip_id = if params[:access_right][:inventory_pool_id] and admin?
                 params[:access_right][:inventory_pool_id]
               else
                 current_inventory_pool.id
               end
    end
  end

  before_action only: [:edit,
                       :update,
                       :destroy,
                       :set_start_screen,
                       :hand_over,
                       :take_back] do
    # @user = current_inventory_pool.users.find(params[:id])
    @user = User.find(params[:id])
  end

  before_action only: [:hand_over] do
    unless @user.access_right_for(current_inventory_pool)
      redirect_to manage_inventory_pool_users_path,
                  flash: { error: _('No access') }
    end
  end

  private

  # NOTE overriding super controller
  def required_manager_role
    open_actions = [:hand_over]
    if not open_actions.include?(action_name.to_sym) \
      and (request.post? or not request.format.json?)
      super
    else
      require_role :group_manager, current_inventory_pool
    end
  end

  public

  ######################################################################

  def index
    @role = params[:role]
    @users = User.filter params, current_inventory_pool
    set_pagination_header @users unless params[:paginate] == 'false'
  end

  def edit
    @delegation_type = @user.delegation?
    @accessible_roles = get_accessible_roles_for_current_user
    @db_auth = AuthenticationSystemUser.find_by_user_id(@user.id)
    @access_right = @user.access_right_for current_inventory_pool
    @suspendsion = @user.suspensions.find_by(
      inventory_pool: current_inventory_pool
    )
  end

  ### update / put ############################################################

  def update_entitlement_groups
    if params[:user]
      if params[:user].key?(:groups)
        groups = params[:user].delete(:groups)
        @user.entitlement_groups = groups.map { |g| EntitlementGroup.find g['id'] }
      else
        @user.entitlement_groups = []
      end
    end
  end

  def update_user_password
    if params[:db_auth]
      password = params[:db_auth][:password]
      if password.present?
        password_confirmation = params[:db_auth][:password_confirmation]
        raise 'password mismatch' if password != password_confirmation
        dbauth = AuthenticationSystemUser.find_or_create_by!(
          user_id: @user.id,
          authentication_system_id: 'password'
        )
        dbauth.update_attributes!(data: get_pw_hash(password))
      end
    end
  end

  def update_access_rights
    # rubocop:disable Style/IfInsideElse
    @access_right = AccessRight.find_by(
      user_id: @user.id, inventory_pool_id: @ip_id
    )

    if params[:access_right][:role].try(&:to_sym) == :no_access
      if @access_right
        unless @access_right.destroy
          raise @access_right.errors.messages.values.flatten.first
        end
      end
    else
      if not @access_right
        @access_right = AccessRight.create(
          { user_id: @user.id,
            inventory_pool_id: @ip_id }.merge(params[:access_right])
        )
      else
        @access_right.update_attributes! params[:access_right]
      end
    end
    # rubocop:enable Style/IfInsideElse
  end

  def update_respond_success
      respond_to do |format|
        format.html do
          flash[:notice] = _('User details were updated successfully.')
          redirect_to manage_inventory_pool_users_path
        end
        format.json do
          render plain: _('User details were updated successfully.')
        end
      end
  end

  def update_respond_error(e)
    respond_to do |format|
      format.html do
        flash[:error] = e.to_s
        redirect_back fallback_location: root_path
      end
      format.json { render plain: e.to_s, status: 500 }
    end
  end

  def update
    begin
      User.transaction(requires_new: true) do
        update_entitlement_groups
        delegated_user_ids = get_delegated_users_ids params
        @user.delegated_user_ids = delegated_user_ids if delegated_user_ids
        @user.update_attributes! params[:user] if params[:user]
        update_user_password
        update_access_rights
        update_respond_success
      end
    rescue => e
      update_respond_error(e)
    end
  end

  #################################################################

  def set_start_screen(path = params[:path])
    if current_user.start_screen(path)
      head :ok
    else
      head :bad_request
    end
  end

  #################################################################

  def get_accessible_roles_for_current_user
    accessible_roles = [[_('No access'), :no_access], [_('Customer'), :customer]]
    unless @delegation_type
      accessible_roles +=
        if @current_user.is_admin \
          or @current_user.has_role? :inventory_manager, @current_inventory_pool
          [[_('Group manager'), :group_manager],
           [_('Lending manager'), :lending_manager],
           [_('Inventory manager'), :inventory_manager]]
        elsif @current_user.has_role? :lending_manager, @current_inventory_pool
          [[_('Group manager'), :group_manager],
           [_('Lending manager'), :lending_manager]]
        else
          []
        end
    end
    accessible_roles
  end

  def hand_over
    set_shared_visit_variables 0 do
      @reservations = \
        @user
        .reservations
        .where(status: :approved, inventory_pool: current_inventory_pool)
      @orders = @reservations.map(&:order)
      @models = @reservations.map(&:model).select { |m| m.type == 'Model' }.uniq
      @software = \
        @reservations.map(&:model).select { |m| m.type == 'Software' }.uniq
      @options = \
        @reservations.where.not(option_id: nil).map(&:option).uniq
      @items = \
        @reservations.where.not(item_id: nil)
        .map(&:item)
        .select { |i| i.type == 'Item' }
      @licenses = \
        @reservations.where.not(item_id: nil)
        .map(&:item)
        .select { |i| i.type == 'License' }
    end
    @start_date, @end_date = \
      @grouped_lines.keys.sort.first || [Time.zone.today, Time.zone.today]
    add_visitor(@user)
  end

  def take_back
    set_shared_visit_variables 1 do
      @reservations = \
        @user
          .reservations
          .signed
          .where(inventory_pool_id: current_inventory_pool)
          .includes([:model, :item, :order])
      @contracts = \
        @user
          .contracts
          .open
          .where(inventory_pool_id: current_inventory_pool)
      @models = @reservations.map(&:model).uniq
      @options = \
        @reservations.where.not(option_id: nil).map(&:option).uniq
      @items = \
        @reservations.where.not(item_id: nil)
        .map(&:item)
    end
    @start_date = @reservations.map(&:start_date).min || Time.zone.today
    @end_date = @reservations.map(&:end_date).max || Time.zone.today
    add_visitor(@user)
  end

  private

  def set_shared_visit_variables(date_index)
    @user = User.find(params[:id]) if params[:id]
    @group_ids = @user.entitlement_group_ids
    yield
    @grouped_lines = @reservations.group_by { |g| [g.start_date, g.end_date] }
    @grouped_lines.each_pair do |k, reservations|
      @grouped_lines[k] = \
        reservations.sort_by { |line| [line.model.name, line.id] }
    end
    @count_today = \
      @grouped_lines.keys.count { |range| range[date_index] == Time.zone.today }
    @count_future = \
      @grouped_lines.keys.count { |range| range[date_index] > Time.zone.today }
    @count_overdue = \
      @grouped_lines.keys.count { |range| range[date_index] < Time.zone.today }
    @grouped_lines_by_date = []
    @grouped_lines.each_pair do |range, reservations|
      @grouped_lines_by_date
        .push(date: range[date_index], grouped_lines: { range => reservations })
    end
    @grouped_lines_by_date = @grouped_lines_by_date.sort_by { |g| g[:date] }
  end

  def get_delegated_users_ids(params)
    # for complete users replacement, get only user ids without the _destroy flag
    if users = (params[:user] && params[:user].delete(:users))
      users.select { |h| h['_destroy'] != '1' }.map { |h| h['id'] }
    end
  end

  def get_pw_hash(password)
    ActiveRecord::Base.connection.execute(<<-SQL.strip_heredoc)
      SELECT crypt(
        #{ActiveRecord::Base.sanitize(password)},
        gen_salt('bf',10)
      ) AS pw_hash
    SQL
    .first['pw_hash']
  end
end
