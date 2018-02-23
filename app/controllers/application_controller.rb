class ApplicationController < ActionController::Base
  include MainHelpers
  include Concerns::UserSessionController

  layout 'splash'

  # FIXME: workaround for this bug:
  #       <https://github.com/charliesome/better_errors/issues/341>
  before_action :better_errors_hack, if: -> { Rails.env.development? }

  def status
    render json: {
      db_schema_migrations_max_version: ActiveRecord::Base.connection \
        .select_values('select max(version::int) from schema_migrations').first
    }, status: 200
  end

  def root
    if not User.exists?
      redirect_to new_first_admin_user_path
    elsif logged_in?
      flash.keep
      if current_user.has_role?(:admin)
        redirect_to admin.root_path
      elsif current_user.has_role?(:group_manager)
        redirect_to manage_root_path
      else
        redirect_to borrow_root_path
      end
    end
  end

  def new_first_admin_user
    if User.exists?
      render :forbidden, body: 'Admin user already exists!'
    else
      @user = User.new
    end
  end

  def create_first_admin_user
    if User.exists?
      head :forbidden
    else
      ApplicationRecord.transaction do
        setup_default_database_authentication_system!
        db_auth_system = \
          AuthenticationSystem.find_by_class_name!('DatabaseAuthentication')
        user = \
          User.create! user_params.merge(authentication_system: db_auth_system)
        DatabaseAuthentication.create! db_auth_params.merge(user: user)
        AccessRight.create! user: user, role: :admin
      end
      flash[:notice] = _(
        'First admin user has been created. ' \
        'Default database authentication system has been configured.'
      )
      redirect_to root_path
    end
  end

  private

  def setup_default_database_authentication_system!
    AuthenticationSystem.update_all(is_default: false)
    auth_system = AuthenticationSystem.find_or_initialize_by(
      class_name: 'DatabaseAuthentication'
    )
    auth_system.name ||= 'Database Authentication'
    auth_system.is_active = true
    auth_system.is_default = true
    auth_system.save!
  end

  def user_params
    params
      .require(:user)
      .merge login: db_auth_params.fetch(:login)
  end

  def db_auth_params
    params.require(:db_auth)
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
