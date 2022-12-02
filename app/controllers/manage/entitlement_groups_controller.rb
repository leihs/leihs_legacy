class Manage::EntitlementGroupsController < Manage::ApplicationController

  before_action do
    params[:group_id] ||= params[:id] if params[:id]
    if params[:group_id]
      @group = current_inventory_pool.entitlement_groups.find(params[:group_id])
    end
  end

  def map_params(params)
    ActionController::Parameters.new(params[:group].to_h.map do |k, v|
      case k
      when 'partitions_attributes'
        [:entitlements_attributes, v.map do |ep|
          ActionController::Parameters.new (ep.map do |k, v|
            case k
            when 'group_id'
              [:entitlement_group_id, v]
            else
              [k, v]
            end
          end.to_h)
        end]
      else
        [k, v]
      end
    end.to_h)
  end

  ######################################################################

  def index
    @groups = current_inventory_pool.entitlement_groups
    @groups = @groups.where(id: params[:group_ids]) if params[:group_ids]
    @groups = @groups.search(params[:search_term]) if params[:search_term]
    @groups = @groups.order(:name)
  end

  def new
  end

  def edit
  end

  def create
    @group = EntitlementGroup.new name: params[:group][:name]
    @group.inventory_pool = current_inventory_pool
    if params[:group].key?(:users)
      update_users(@group, params[:group].delete(:users))
    end
    mapped_params = map_params params
    mapped_params.permit!
    mapped_params.delete(:users)
    if @group.save and @group.update_attributes(mapped_params)
      redirect_to manage_inventory_pool_groups_path,
                  flash: { success: _('%s created') % _('Entitlement-Group') }
    else
      redirect_back fallback_location: root_path,
                    flash: { error: @group.errors.full_messages.uniq.join(', ') }
    end
  end

  def update
    if params[:group].key?(:users)
      update_users(@group, params[:group].delete(:users))
    end
    mapped_params = map_params params
    mapped_params.permit!
    mapped_params.delete(:users)
    if @group.update_attributes(mapped_params)
      redirect_to manage_inventory_pool_groups_path,
                  flash: { success: _('%s saved') % _('Entitlement-Group') }
    else
      render plain: @group.errors.full_messages.uniq.join(', '),
             status: :bad_request
    end
  end

  def destroy
    respond_to do |format|
      format.html do
        begin
          @group.destroy
          redirect_to \
            manage_inventory_pool_groups_path,
            flash: { success: _('%s successfully deleted') % _('Entitlement-Group') }
        rescue ActiveRecord::DeleteRestrictionError => e
          @group.errors.add(:base, e)
          redirect_to \
            manage_inventory_pool_groups_path,
            flash: { error: @group.errors.full_messages.uniq.join(', ') }
        end
      end
    end
  end

  #################################################################

  private ####

  def update_users(group, users)
    users.each do |user|
      if user['_destroy'] == '1' or user['_destroy'] == 'true'
        group.users.delete User.find(user['id'])
      elsif group.users.find_by_id(user['id']).nil?
        group.users << User.find(user['id'])
      end
    end
    group.users
  end

end
