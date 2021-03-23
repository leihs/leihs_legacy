module AuthenticatedSystem
  protected

  # Returns true or false if the user is logged in.
  def logged_in?
    current_user != nil
  end

  def access_denied
    if request.xhr? and not logged_in?
      # for ajax requests when logged out, yield correct error status code to force a sign-in action
      render status: 401, plain: _("You don't have permission to perform this action")
    else
      if request.get?
        redirect_to(sign_in_path + '?' + ({'return-to' => request.fullpath}).to_query)
      else
        # NOTE: the error message should mention the need to sign-in, if thats the problem?
        # We dont do anything fancy so the user does not lose the POST data. But, that only works if they sign in in another browser tab.
        render status: :method_not_allowed,
        plain: _("You don't have permission to perform this action")
      end
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
