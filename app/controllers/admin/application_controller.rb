class Admin::ApplicationController < ApplicationController
  layout 'admin'

  before_action do
    not_authorized!(redirect_path: root_path) unless admin?
  end
end
