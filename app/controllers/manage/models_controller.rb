class Manage::ModelsController < Manage::ApplicationController
  include FileStorage
  include WorkaroundRailsBug25198

  private

  # NOTE overriding super controller
  def required_manager_role
    open_actions = [:timeline, :old_timeline]
    if not open_actions.include?(action_name.to_sym) \
      and (request.post? or not request.format.json?)
      super
    else
      require_role :group_manager, current_inventory_pool
    end
  end

  public

  def index
    @models = Model.filter params, current_inventory_pool
    set_pagination_header(@models) unless params[:paginate] == 'false'
  end

  def show
    @model = fetch_model
  end

  def new
    not_authorized! unless privileged_user?
    @model = (params[:type].try(:humanize) || 'Model').constantize.new
  end

  def create
    not_authorized! unless privileged_user?
    created = false
    ApplicationRecord.transaction do
      @model = case params[:model][:type]
               when 'software'
                   Software
               else
                   Model
               end.create(product: params[:model][:product],
                          version: params[:model][:version])
      save_model(@model)
      if !@model.persisted? or @model.errors.any?
        raise ActiveRecord::Rollback
      else
        created = true
      end
    end

    unless created
      render status: :bad_request,
             plain: @model.errors.full_messages.uniq.join(', ')
    else
      render status: :ok, json: { id: @model.id }
    end
  end

  def edit
    @model = fetch_model
  end

  def update
    not_authorized! unless privileged_user?
    @model = fetch_model
    ApplicationRecord.transaction do
      if save_model @model
        head :ok
      else
        render status: :bad_request,
               plain: @model.errors.full_messages.uniq.join(', ')
      end
    end
  end

  def upload
    @model = fetch_model
    params[:files].each do |file|
      if params[:type] == 'image'
        store_image_with_thumbnail!(file, @model)
      elsif params[:type] == 'attachment'
        store_attachment!(file, model_id: @model.id)
      end
    end
    head :ok
  end

  def destroy
    @model = fetch_model
    begin
      @model.destroy
      respond_to do |format|
        format.json { render json: true, status: :ok }
        format.html do
          redirect_to \
            manage_inventory_path(current_inventory_pool),
            flash: { success: _('%s successfully deleted') % _('Model') }
        end
      end
    rescue => e
      @model.errors.add(:base, e)
      text = @model.errors.full_messages.uniq.join(', ')
      respond_to do |format|
        format.json { render plain: text, status: :forbidden }
        format.html do
          redirect_to \
            manage_inventory_path(current_inventory_pool),
            flash: { error: text }
        end
      end
    end
  end

  def old_timeline
    @model = fetch_model
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  include TimelineAvailability
  def timeline
    @props = {
      timeline_availability: timeline_availability(
        fetch_model.id, current_inventory_pool.id, lending_manager?
      )
    }
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  private

  def fetch_model
    Model.filter(params).first
  end

  def update_packages(packages)
    packages.each do |package|
      package = packages[package]
      children = package.delete(:children)
      if package['id'].blank?
        ApplicationRecord.transaction do
          item = Item.new
          data = package.merge owner_id: current_inventory_pool.id,
                               model: @model
          data[:inventory_code] ||= \
            "P-#{Item.proposed_inventory_code(current_inventory_pool)}"
          item.update_attributes data
          children['id'].each do |child_id|
            child = Item.find(child_id)
            child.skip_serial_number_validation = true
            inherit_attributes_from_package!(item, child)
            item.children << child
          end
          flash[:success] = "#{_('Model saved')} / #{_('Packages created')}"
        end
      else
        item = Item.find_by_id(package['id'])
        if package['_destroy'] == '1'
          if item.reservations.empty?
            item.destroy
          else
            item.retired = true
            item.retired_reason = format('%s %s', _('Package'), _('Deleted'))
            item.save
          end
          next
        elsif item
          package.delete '_destroy'
          item.update_attributes package
          if children
            item.children = []
            children['id'].each do |child_id|
              child = Item.find(child_id)
              child.skip_serial_number_validation = true
              inherit_attributes_from_package!(item, child)
              item.children << child
            end
          end
        end
        flash[:success] = "#{_('Model saved')} / #{_('Packages updated')}"
      end
    end
  end

  private

  def inherit_attributes_from_package!(package, item)
    item.update_attributes!(room_id: package.room_id,
                            shelf: package.shelf)
  end

  def save_model(model)
    # PACKAGES
    packages = params[:model].delete(:packages)
    if packages
      @model.is_package = true
      update_packages packages
    end
    # COMPATIBLES
    model.compatibles = []
    # PROPERTIES
    model.properties.destroy_all
    # REMAINING DATA
    params[:model].delete(:type)
    ###############################################################################
    # TODO: # Rails bug: https://github.com/rails/rails/issues/25198
    deal_with_destroy_nested_attributes!(params[:model])
    ###############################################################################
    p = ActionController::Parameters.new(params[:model].map do |k, v|
      case k
      when 'partitions_attributes'
        [:entitlements_attributes, ActionController::Parameters.new(v.map do |k, v|
          [k, ActionController::Parameters.new(v.map do |k, v|
            case k
            when 'group_id'
              [:entitlement_group_id, v]
            else
              [k, v]
            end
          end.to_h)]
        end.to_h)]
      else
        [k, v]
      end
    end.to_h)
    p.permit!
    model.update_attributes(p) and model.save
  end

end
