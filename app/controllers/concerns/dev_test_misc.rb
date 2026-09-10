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

        # Regression test for Madek/Madek#946: catches a genuine DB-level
        # abort locally (like a real controller's rescue block would), calls
        # `redirect_to` -- which should heal the connection -- and then
        # writes to the DB again. If the heal didn't happen, this write
        # silently fails to persist (connection still aborted at that
        # point), which the spec observes as a missing Language row, without
        # needing the request itself to crash.
        def redirect_then_query
          begin
            ActiveRecord::Base.connection.execute('SELECT 1/0')
          rescue ActiveRecord::StatementInvalid
          end

          redirect_to status_path

          begin
            Language.create!(name: 'Test Language After Redirect', locale: 'xx')
          rescue ActiveRecord::StatementInvalid
          end
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

        cookies[Leihs::Constants::USER_SESSION_COOKIE_NAME] = { value: token }
        redirect_to manage_root_path
      end

      def sign_out
        if current_user
          UserSession.where(user: current_user).destroy_all
        end
        cookies.delete Leihs::Constants::USER_SESSION_COOKIE_NAME
        flash[:notice] = _('You have been logged out.')
        redirect_back_or_default('/')
      end

      def root
        # NOTE: this is only used in DEV/TEST (in PROD, the root page goes to `my` service). We set the "redirect-reason" only to track this…
        if logged_in?
          flash.keep
          if current_user.is_admin
            redirect_to '/admin'
          elsif current_user.has_role?(:group_manager)
            redirect_to manage_root_path
          elsif current_user.access_rights.any?
            redirect_to '/borrow'
          else
            redirect_to '/my/auth-info?redirect-reason=no-access-legacy-root'
          end
        end
      end
    end
  end
end
