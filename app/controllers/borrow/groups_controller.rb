class Borrow::GroupsController < Borrow::ApplicationController

  def index
    @groups = current_user.entitlement_groups
  end
end
