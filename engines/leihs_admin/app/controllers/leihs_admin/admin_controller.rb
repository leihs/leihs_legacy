module LeihsAdmin
  class AdminController < ApplicationController
    layout 'leihs_admin/admin'

    before_action do
      not_authorized!(redirect_path: main_app.root_path) unless admin?
    end
  end
end
