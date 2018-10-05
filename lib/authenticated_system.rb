module AuthenticatedSystem
  protected

  # Returns true or false if the user is logged in.
  def logged_in?
    current_user != nil
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied
    if request.get?
      store_location
      flash[:notice] = _("You don't have permission to perform this action")
      redirect_to root_path
    else
      # NOTE in case of post requests
      render status: :method_not_allowed,
             plain: _("You don't have permission to perform this action")
    end
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = \
      request.fullpath # sellittf#Rails3.1# request.request_uri
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :user_session, :logged_in?
  end

  def require_role(role, inventory_pool = nil)
    if current_user and current_user.has_role?(role, inventory_pool)
      true
    else
      access_denied
    end
  end

end
