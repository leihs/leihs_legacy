class SessionsController < ApplicationController

  def authenticate(id = params[:id])
    @selected_system = AuthenticationSystem.active_systems.find(id) if id
    @selected_system ||= AuthenticationSystem.default_system.first
    sys = "Authenticator::#{@selected_system.class_name}Controller".constantize.new
    redirect_to sys.login_form_path
  rescue
    logger.error($!)
    unless AuthenticationSystem.default_system.first
      raise 'No default authentication system selected.'
    end
    raise 'No system selected.' unless @selected_system
    raise 'Class not found or missing login_form_path method: ' \
      + @selected_system.class_name
  end

  def authenticate_as
    if Rails.env.development? \
      and self.current_user = User.find(params[:id])
      redirect_back_or_default('/')
      flash[:notice] = _('Logged in successfully')
    end
  end

  def destroy
    # store last inventory pool to the settings column
    if current_user
      current_user.latest_inventory_pool_id_before_logout = \
        session[:current_inventory_pool_id]
      current_user.save
    end
    # delete cookie and reset session
    cookies.delete :auth_token
    cookies.delete 'leihs-user-session'
    reset_session
    # redirect and flash
    flash[:notice] = _('You have been logged out.')
    # TODO move this to a user property
    session[:locale] = current_user.language.locale_name if current_user
    redirect_back_or_default('/')
  end
end
