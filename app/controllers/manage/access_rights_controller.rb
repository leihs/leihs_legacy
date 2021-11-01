class Manage::AccessRightsController < Manage::ApplicationController

  def index
    @access_rights = if params[:user_ids]
                       current_inventory_pool
                         .access_rights
                         .active
                         .where(user_id: params[:user_ids])
                         .map {|ar| {
                           role: ar.role,
                           user_id: ar.user_id,
                           inventory_pool_id: ar.inventory_pool_id,
                           suspended_until: ar.suspended_until}
                         }
                     else
                       raise 'User ids required'
                     end
  end

end
