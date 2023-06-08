# enable login without password in dev and test

module DevTestMisc
  extend ActiveSupport::Concern

  included do
    if Rails.env.development? or Rails.env.test?
      # needed because of some assertions in tests
      if Rails.env.test?
        def borrow
          render plain: "BORROW\nRails-Env: #{Rails.env}\nCurrent-User: #{current_user.name}"
        end
      end

      def sign_in
        user = User.find_by!(email: params[:email])
        token = UUIDTools::UUID.random_create
        token_hash = Digest::SHA256.hexdigest(token)

        # because of time travel in test, AR sets the fake created at otherwise
        real_now = ActiveRecord::Base.connection.execute('SELECT now()').first['now']

        auth_system = AuthenticationSystem.find_by(type: 'password') ||
          AuthenticationSystem.create(id: 'password',
                                      name: 'leihs password',
                                      type: 'password')

        UserSession.create!(user: user,
                            authentication_system: auth_system,
                            token_hash: token_hash,
                            created_at: real_now)

        cookies['leihs-user-session'] = { value: token }
        redirect_to root_path
      end

      def sign_out
        if current_user
          UserSession.where(user: current_user).destroy_all
        end
        cookies.delete 'leihs-user-session'
        flash[:notice] = _('You have been logged out.')
        redirect_back_or_default('/')
      end

      def root
        # NOTE: this is only used in DEV/TEST (in PROD, the root page goes to `my` service). We set the "redirect-reason" only to track this…
        if logged_in?
          flash.keep
          if current_user.is_admin
            redirect_to admin_root_path
          elsif current_user.has_role?(:group_manager)
            redirect_to manage_root_path
          elsif current_user.access_rights.any?
            redirect_to '/borrow'
          else
            redirect_to '/my/user/me?redirect-reason=no-access-legacy-root'
          end
        end
      end
    end
  end
end
