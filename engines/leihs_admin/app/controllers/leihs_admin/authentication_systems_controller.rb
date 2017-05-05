module LeihsAdmin
  class AuthenticationSystemsController < AdminController
    def index
      @authentication_systems = AuthenticationSystem.all
    end
  end
end
