module LeihsAdmin
  class UsersController < AdminController

    def index
      @role = params.permit(:role)[:role]
      @users = User.filter params, current_inventory_pool

      respond_to do |format|
        format.json do
          render json: @users
        end
      end
    end

  end
end
