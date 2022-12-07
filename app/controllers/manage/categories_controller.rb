class Manage::CategoriesController < Manage::ApplicationController
  include FileStorage
  include WorkaroundRailsBug25198

  def index
    respond_to do |format|
      format.html
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

  def new
    @category ||= Category.new
  end

  def create
    @category = Category.new
    update_category
  end

  def edit
    @category ||= Category.find(params[:id])
  end

  def update
    @category = Category.find(params[:id])
    update_category
  end

  def destroy
    @category = Category.find(params[:id])
    @parent = Category.find(params[:parent_id]) unless params[:parent_id].blank?
    if @category and @parent
      @parent.children.delete(@category) # if @parent.children.include?(@category)
      redirect_to \
        manage_inventory_pool_category_parents_path(current_inventory_pool,
                                                    @category)
    else
      if @category.models.empty?
        @category.destroy
        respond_to do |format|
          format.json { head :ok }
          format.html do
            redirect_to \
              manage_categories_path(current_inventory_pool),
              notice: _('%s successfully deleted') % _('Category')
          end
        end
      else
        # TODO: 0607 ajax delete
        @category.errors.add(:base, _('The Category must be empty'))
        render action: 'show' # TODO: 24** redirect to the correct tabbed form
      end
    end
  end

  def upload
    @category = Category.find params[:id]
    params[:files].each do |file|
      next unless params[:type] == 'image'
      store_image_with_thumbnail!(file, @category)
    end
    head :ok
  end

  private

  def update_category
    links = params[:category].delete(:links)
    ###############################################################################
    # TODO: # Rails bug: https://github.com/rails/rails/issues/25198
    deal_with_destroy_nested_attributes!(params[:category])
    ###############################################################################
    if @category.update(params[:category]) and @category.save!
      manage_links @category, links
      render status: :ok, json: { id: @category.id }
    else
      render status: :bad_request,
             text: @model.errors.full_messages.uniq.join(', ')
    end
  end

  def manage_links(category, links)
    return true if links.blank?
    links.each do |link|
      link_id = link.first
      parent = @category.parents.find_by_id(links[link_id]['parent_id'])
      if parent # parent exists already
        existing_link = ModelGroupLink.find_edge(parent, @category)
        if links[link_id]['_destroy'] == '1'
          existing_link.destroy
        else
          existing_link.update_attribute :label, links[link_id]['label']
        end
      else
        parent = Category.find links[link_id]['parent_id']
        category.set_parent_with_label parent, links[link_id]['label']
      end
    end
  end
end
