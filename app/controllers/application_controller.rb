class ApplicationController < ActionController::Base
  include MainHelpers
  include DevTestMisc

  layout 'splash'
  
  # CSRF protection
  protect_from_forgery with: :exception

  attr_reader :user_session, :current_user

  helper_method :about_path
  helper_method :root_path

  ########################### BEFORE_ACTION ##############################

  # https://github.com/Madek/Madek/issues/423
  before_action do
    begin
      session.exists?
    rescue JSON::ParserError
      cookies.delete(Leihs::Constants::Legacy::SESSION_NAME)
    end
  end

  # FIXME: workaround for this bug:
  #       <https://github.com/charliesome/better_errors/issues/341>
  before_action :better_errors_hack, if: -> { Rails.env.development? }

  before_action :authenticate
  before_action :get_and_set_global_csrf_token
  before_action :set_gettext_locale
  before_action :permit_params

  # FIXME!!!
  skip_before_action :verify_authenticity_token

  ##########################################################################

  # excluded from routes.rb that's why
  if Rails.env.production?
    def root_path
      '/'
    end
  end

  def status
    render json: {
      db_schema_migrations_max_version: ActiveRecord::Base.connection \
      .select_values('select max(version::int) from schema_migrations').first
    }, status: 200
  end

  def authenticate
    token = cookies['leihs-user-session']
    @user_session = UserSession.find_by_token(token)
    @current_user = @user_session.try { |us| us.delegation or us.user }
  end

  def get_and_set_global_csrf_token
    @leihs_anti_csrf_token = cookies['leihs-anti-csrf-token']
  end

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
