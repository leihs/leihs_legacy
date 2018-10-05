class ApplicationController < ActionController::Base
  include MainHelpers

  layout 'splash'

  # FIXME: workaround for this bug:
  #       <https://github.com/charliesome/better_errors/issues/341>
  before_action :better_errors_hack, if: -> { Rails.env.development? }

  before_action :authenticate
  before_action :set_gettext_locale
  before_action :permit_params

  # CSRF protection
  protect_from_forgery with: :exception

  # ##############################################
  # ##############################################
  # ##############################################
  # FIXME!!!
  skip_before_action :verify_authenticity_token
  # ##############################################
  # ##############################################
  # ##############################################

  def status
    render json: {
      db_schema_migrations_max_version: ActiveRecord::Base.connection \
      .select_values('select max(version::int) from schema_migrations').first
    }, status: 200
  end

  attr_reader :user_session, :current_user
  def authenticate
    token = cookies['leihs-user-session']
    @user_session = UserSession.find_by_token(token)
    @current_user = @user_session.try { |us| us.delegation or us.user }
  end

  if Rails.env.development? or Rails.env.test?
    def sign_in
      user = User.find_by!(email: params[:email])
      token = UUIDTools::UUID.random_create
      token_hash = Digest::SHA256.hexdigest(token)

      # because of time travel in test, AR sets the fake created at otherwise
      real_now = ActiveRecord::Base.connection.execute('SELECT now()').first['now']

      UserSession.create!(user: user,
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
  end

  def root
    if logged_in?
      flash.keep
      if current_user.is_admin
        redirect_to admin.root_path
      elsif current_user.has_role?(:group_manager)
        redirect_to manage_root_path
      else
        redirect_to borrow_root_path
      end
    end
  end

  private

  # NOTE: see hook on top of file
  def better_errors_hack
    if request.env.key?('puma.config')
      request.env['puma.config'].options.user_options.delete(:app)
    end
  end

  def respond_with_presenter(presenter)
    fail 'Not a Presenter' unless presenter.is_a?(ApplicationPresenter)
    respond_to do |format|
      format.html { render(locals: { get: presenter }) }
      format.json { render_json(presenter) }
    end
  end

  def render_json(presenter)
    render(json: JSON.pretty_generate(presenter.dump))
  end

end
