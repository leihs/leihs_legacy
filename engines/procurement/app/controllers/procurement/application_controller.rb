module Procurement
  class ApplicationController < ActionController::Base
    include MainHelpers

    helper_method :settings
    helper_method :procurement_requester?
    helper_method :procurement_inspector?
    helper_method :procurement_admin?
    helper_method :procurement_or_leihs_admin?

    before_action :before_action_check_access

    def root
      redirect_to overview_requests_path if current_user
    end

    private

    def settings
      OpenStruct.new(Procurement::Setting.all_as_hash)
    end

    def procurement_or_leihs_admin?
      Access.admin?(current_user) or
        (Access.admins.empty? and current_user.has_role?(:admin))
    end

    def procurement_requester?
      Access.requesters.where(user_id: current_user).exists?
    end

    def procurement_inspector?
      Procurement::Category.inspector_of_any_category?(current_user)
    end

    def procurement_admin?
      Procurement::Access.admin?(current_user)
    end

    def procurement_access?
      procurement_requester? or
        procurement_inspector? or
        procurement_or_leihs_admin?
    end

    def before_action_check_access
      unless current_user
        # raise Errors::UnauthorizedError
        redirect_to main_app.login_path and return
      end
      unless procurement_access?
        # raise Errors::ForbiddenError
        redirect_to main_app.root_path and return
      end
    end

  end
end
