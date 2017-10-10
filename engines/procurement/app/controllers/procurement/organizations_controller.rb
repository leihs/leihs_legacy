require_dependency 'procurement/application_controller'

module Procurement
  class OrganizationsController < ApplicationController

    before_action do
      unless procurement_admin?
        raise Errors::ForbiddenError
      end
    end

    def index
      @organizations = Organization.roots
    end

  end
end
