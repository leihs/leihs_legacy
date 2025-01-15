class Manage::CategoriesController < Manage::ApplicationController
  def index
    respond_to do |format|
      format.json do
        @categories = Category.filter(params, current_inventory_pool).to_a
        if not params[:include] or not params[:include][:used?]
          cat = Category.new(name: format('* %s *', _('Not categorized')))
          cat.id = UUIDTools::UUID.parse('00000000-0000-0000-0000-000000000000')
          @categories << cat
        end
        @include_information = params[:include].keys if params[:include]
      end
    end
  end
end
