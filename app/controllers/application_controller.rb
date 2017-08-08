class ApplicationController < ActionController::Base
  include MainHelpers

  layout 'splash'

  def root
    if not User.exists?
      redirect_to new_first_admin_user_path
    elsif logged_in?
      flash.keep
      if current_user.has_role?(:admin)
        redirect_to admin.root_path
      elsif current_user.has_role?(:group_manager)
        redirect_to manage_root_path
      else
        redirect_to borrow_root_path
      end
    end
  end

  def new_first_admin_user
    if User.exists?
      render :forbidden, body: 'Admin user already exists!'
    else
      @user = User.new
    end
  end

  def create_first_admin_user
    if User.exists?
      head :forbidden
    else
      ApplicationRecord.transaction do
        setup_default_database_authentication_system!
        db_auth_system = \
          AuthenticationSystem.find_by_class_name!('DatabaseAuthentication')
        user = \
          User.create! user_params.merge(authentication_system: db_auth_system)
        DatabaseAuthentication.create! db_auth_params.merge(user: user)
        AccessRight.create! user: user, role: :admin
      end
      flash[:notice] = _(
        'First admin user has been created. ' \
        'Default database authentication system has been configured.'
      )
      redirect_to root_path
    end
  end

  private

  def setup_default_database_authentication_system!
    AuthenticationSystem.update_all(is_default: false)
    auth_system = AuthenticationSystem.find_or_initialize_by(
      class_name: 'DatabaseAuthentication'
    )
    auth_system.name ||= 'Database Authentication'
    auth_system.is_active = true
    auth_system.is_default = true
    auth_system.save!
  end

  def user_params
    params
      .require(:user)
      .merge login: db_auth_params.fetch(:login)
  end

  def db_auth_params
    params.require(:db_auth)
  end
end
