require 'cider_ci/open_session/encryptor'

module AuthenticatedSystem
  protected

  attr_accessor :user_session

  # Returns true or false if the user is logged in.
  def logged_in?
    current_user != nil
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    @current_user ||=
      unless @current_user == false
        user_by_session
      end
  end

  def current_user=(user)
    create_user_session(user) if user
    @current_user = user || false
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
      redirect_to login_path
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

  # Called from #current_user.
  # First attempt to login by the user id stored in the session.
  def login_from_session
    self.current_user = User.find_by_id(session[:user_id]) if session[:user_id]
  end

  def require_role(role, inventory_pool = nil)
    if current_user and current_user.has_role?(role, inventory_pool)
      true
    else
      access_denied
    end
  end


  ### leihs-user-session cookie stuff #########################################

  USER_SESSION_COOKIE_NAME = 'leihs-user-session'

  def secret
    Rails.application.secrets.secret_key_base.presence \
      || raise('secret_key_base is missing')
  end

  def validate_lifetime_duration!(lifetime, max_lifetime)
    if lifetime > max_lifetime
      raise 'The session has expired!'
    end
  end

  def validate_lifetime!(user_session)
    lifetime = Time.zone.now - user_session.created_at
    if lifetime >
      (Setting.first.try(:sessions_max_lifetime_secs) || (5*24*60*60))
      raise 'The session has expired!'
    end
  end

  def user_by_session
    if user_session_cookie = cookies[USER_SESSION_COOKIE_NAME].presence
      begin
        session_object = CiderCi::OpenSession::Encryptor.decrypt(
          secret, user_session_cookie).deep_symbolize_keys
          @user_session= UserSession.find_by! token_hash: Digest::SHA256.hexdigest(session_object[:token])
          validate_lifetime!(@user_session)
          @user_session.user
      rescue Exception => e
        Rails.logger.warn e
        reset_session
        cookies.delete USER_SESSION_COOKIE_NAME
        nil
      end
    end
  end

  def create_user_session(user)
    token = SecureRandom.uuid
    token_hash = Digest::SHA256.hexdigest token
    cookies.permanent[USER_SESSION_COOKIE_NAME] =
      CiderCi::OpenSession::Encryptor.encrypt(
        secret, user_id: user.id,
        token: token)
    if Setting.first.try(:sessions_force_uniqueness) \
        && !user.delegation?
      UserSession.destroy_all(user_id: user.id)
    end
    @user_session = UserSession.create user_id: user.id, token_hash: token_hash
  end

end
