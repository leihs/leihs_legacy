class CategoryLinksController < ApplicationController

  def index
    @links =
      if params[:parent_id].presence
        ModelGroupLink.where(parent_id: params[:parent_id])
      else
        ModelGroupLink.all
      end
  end

end
