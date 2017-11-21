class Authenticator::AuthenticatorController < ApplicationController

  def login
    # TODO move this to a user property
    session[:locale] = nil
  end

end
